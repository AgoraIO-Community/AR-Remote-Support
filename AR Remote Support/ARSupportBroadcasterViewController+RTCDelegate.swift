//
//  ARSupportBroadcasterViewController+RTCDelegate.swift
//  AR Remote Support
//
//  Created by Max Cobb on 30/09/2021.
//  Copyright © 2021 Agora.io. All rights reserved.
//

import AgoraRtcKit
import AgoraRtmKit
import SceneKit
import SCNLine

extension ARSupportBroadcasterViewController: AgoraRtcEngineDelegate {
    // MARK: AGORA DELEGATE
    func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoDecodedOfUid uid: UInt, size: CGSize, elapsed: Int) {
        if uid == self.remoteUser {
            self.sessionIsActive = true
            self.streamIsEnabled = self.agoraKit.createDataStream(&self.dataStreamId, reliable: true, ordered: true)
            if debug {
                print("Data Stream initiated - STATUS: \(self.streamIsEnabled)")
            }
        }

    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        if debug {
            print("remote user did offline of uid: \(uid)")
        }
        if uid == self.remoteUser {
            self.remoteUser = nil
        }
    }
}

extension ARSupportBroadcasterViewController: AgoraRtmChannelDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, receiveStreamMessageFromUid uid: UInt, streamId: Int, data: Data) {
        let dataString = String(data: data, encoding: .ascii)!
        self.handleNewMessage(dataString)
    }
    func channel(_ channel: AgoraRtmChannel, messageReceived message: AgoraRtmMessage, from member: AgoraRtmMember) {
        if message.type == .text {
            self.handleNewMessage(message.text)
        }
    }

    func updateColor(to colorString: String) {
        var colorString = colorString
        if debug {
            print("color msg recieved\n - \(colorString)")
        }
        // remove the [ ] characters from the string
        guard let openBracketIndex = colorString.firstIndex(of: "["),
           let closeBracketIndex = colorString.firstIndex(of: "]") else {
               fatalError("Could not decode color: \(colorString)")
        }

        colorString.removeSubrange(closeBracketIndex...)
        colorString.removeSubrange(...openBracketIndex)
        // convert the string into an array -- using , as delimeter
        let colorComponents = colorString.components(separatedBy: ", ").map {
            CGFloat(NSString(string: $0).floatValue)
        }

        // safely convert the string values into numbers
        self.lineColor = .init(
            red: colorComponents[0], green: colorComponents[1],
            blue: colorComponents[2], alpha: colorComponents[3]
        )
    }

    func incomingTouchStarted() {
        DispatchQueue.main.async {
            let touchRootNode = SCNLineNode(with: [], radius: 0.005)
            let lineMat = SCNMaterial()
            lineMat.diffuse.contents = self.lineColor
            touchRootNode.lineMaterials = [lineMat]

//                let touchRootNode : SCNNode = SCNNode() // create an empty node to serve as our root for the incoming points
//                touchRootNode.position = currentPostionOfCamera // place the root node ad the center of the camera's frustum
//                touchRootNode.scale = SCNVector3(1.25, 1.25, 1.25)// touches projected in Z will appear smaller than expected - increase scale of root node to compensate
            guard let sceneView = self.sceneView else { return }
            sceneView.scene.rootNode.addChildNode(touchRootNode) // add the root node to the scene

            self.touchRoots.append(touchRootNode)
        }
    }

    func handleNewMessage(_ message: String) {
        switch message {
        case let dataString where dataString.contains("color:"):
            self.updateColor(to: dataString)
        case "undo":
            if !self.touchRoots.isEmpty {
                let latestTouchRoot: SCNNode = self.touchRoots.removeLast()
                latestTouchRoot.isHidden = true
                latestTouchRoot.removeFromParentNode()
            }
        case "touch-start":
            // touch-starts
            print("touch-start msg recieved")
            // add root node for points received
            self.incomingTouchStarted()
        case "touch-end":
            if debug {
                print("touch-end msg recieved")
            }
        case let dataString where dataString.contains("frame-size:"):
            self.handleFrameSize(dataString)
        default:
            if debug {
                print("touch points msg recieved")
            }
            self.parseTouchPoints(message)
        }
    }
    func handleFrameSize(_ dataString: String) {
        var frameSizeStr = dataString
        if debug {
            print("frame size recieved\n - \(frameSizeStr)")
        }
        // remove the [ ] characters from the string
        guard let openBracketIndex = frameSizeStr.firstIndex(of: "["),
           let closeBracketIndex = frameSizeStr.firstIndex(of: "]") else {
               fatalError("Could not decode size: \(frameSizeStr)")
        }

        frameSizeStr.removeSubrange(closeBracketIndex...)
        frameSizeStr.removeSubrange(...openBracketIndex)
        // convert the string into an array -- using , as delimeter
        let frameSizeComponents = frameSizeStr.components(separatedBy: ", ").map {
            CGFloat(NSString(string: $0).floatValue)
        }
        let frameSizeRatio = frameSizeComponents[1] / frameSizeComponents[0]
        let drawableHeight = self.sceneView.frame.width * frameSizeRatio
        self.drawableFrame = CGRect(
            origin: CGPoint(x: 0, y: (drawableHeight - self.sceneView.frame.height) / 2),
            size: CGSize(width: self.sceneView.frame.width, height: drawableHeight)
        )
        self.drawableMult = self.sceneView.frame.width / frameSizeComponents[0]

    }
    func parseTouchPoints(_ pointString: String) {
        // convert data string into an array -- using given pattern as delimeter
        let arrayOfPoints = pointString.components(separatedBy: "), (")
            .compactMap { point -> CGPoint? in
                let comps = point.components(separatedBy: ", ")
                if comps.count == 2, let x = Double(comps[0]), let y = Double(comps[1]) {
                    let newpt = CGPoint(x: x, y: y)
                    if debug {
                        print("CGPOINT: \(newpt)")
                    }
                    return newpt
                }
                return CGPoint?.none
            }

        if debug {
            print("arrayOfPoints: \(arrayOfPoints)")
        }
        remotePoints.append(contentsOf: arrayOfPoints)

    }
}
