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

extension ARSupportBroadcasterViewController {
    // MARK: AGORA DELEGATE
    func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoDecodedOfUid uid:UInt, size:CGSize, elapsed:Int) {
        if uid == self.remoteUser {
            self.sessionIsActive = true
            // TODO: replace with RTM
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
        switch dataString {
        case var dataString where dataString.contains("color:"):
            if debug {
                print("color msg recieved\n - \(dataString)")
            }
            // remove the [ ] characters from the string
            if let closeBracketIndex = dataString.firstIndex(of: "]") {
                dataString.remove(at: closeBracketIndex)
                dataString = dataString.replacingOccurrences(of: "color: [", with: "")
            }
            // convert the string into an array -- using , as delimeter
            let colorComponentsStringArray = dataString.components(separatedBy: ", ")
            // safely convert the string values into numbers
            guard let redColor = NumberFormatter().number(from: colorComponentsStringArray[0]) else { return }
            guard let greenColor = NumberFormatter().number(from: colorComponentsStringArray[1]) else { return }
            guard let blueColor = NumberFormatter().number(from: colorComponentsStringArray[2]) else { return }
            guard let colorAlpha = NumberFormatter().number(from: colorComponentsStringArray[3]) else { return }
            // set line color to UIColor from remote user
            self.lineColor = UIColor.init(red: CGFloat(truncating: redColor), green: CGFloat(truncating: greenColor), blue: CGFloat(truncating:blueColor), alpha: CGFloat(truncating:colorAlpha))
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
            guard let pointOfView = self.sceneView.pointOfView else { return }
            let transform = pointOfView.transform // transformation matrix
            let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33) // camera rotation
            let location = SCNVector3(transform.m41, transform.m42, transform.m43) // location of camera frustum
            let currentPostionOfCamera = orientation + location // center of frustum in world space
            DispatchQueue.main.async {
                let touchRootNode : SCNNode = SCNNode() // create an empty node to serve as our root for the incoming points
                touchRootNode.position = currentPostionOfCamera // place the root node ad the center of the camera's frustum
                touchRootNode.scale = SCNVector3(1.25, 1.25, 1.25)// touches projected in Z will appear smaller than expected - increase scale of root node to compensate
                guard let sceneView = self.sceneView else { return }
                sceneView.scene.rootNode.addChildNode(touchRootNode) // add the root node to the scene
                let constraint = SCNLookAtConstraint(target: self.sceneView.pointOfView) // force root node to always face the camera
                constraint.isGimbalLockEnabled = true // enable gimbal locking to avoid issues with rotations from LookAtConstraint
                touchRootNode.constraints = [constraint] // apply LookAtConstraint

                self.touchRoots.append(touchRootNode)
            }
        case "touch-end":
            if debug {
                print("touch-end msg recieved")
            }
        default:
            if debug {
                print("touch points msg recieved")
            }
            // convert data string into an array -- using given pattern as delimeter
            let arrayOfPoints = dataString.components(separatedBy: "), (")

            if debug {
                print("arrayOfPoints: \(arrayOfPoints)")
            }

            for pointString in arrayOfPoints {
                let pointArray: [String] = pointString.components(separatedBy: ", ")
                // make sure we have 2 points and convert them from String to number
                if pointArray.count == 2, let x = NumberFormatter().number(from: pointArray[0]), let y = NumberFormatter().number(from: pointArray[1]) {
                    let remotePoint: CGPoint = CGPoint(x: CGFloat(truncating: x), y: CGFloat(truncating: y))
                    self.remotePoints.append(remotePoint)
                    if debug {
                        print("POINT - \(pointString)")
                        print("CGPOINT: \(remotePoint)")
                    }
                }
            }
        }

    }
    func channel(_ channel: AgoraRtmChannel, messageReceived message: AgoraRtmMessage, from member: AgoraRtmMember) {
        if message.type == .text {
            let dataStr = message.text
            switch dataStr {
            case var dataString where dataString.contains("color:"):
                if debug {
                    print("color msg recieved\n - \(dataString)")
                }
                // remove the [ ] characters from the string
                if let closeBracketIndex = dataString.firstIndex(of: "]") {
                    dataString.remove(at: closeBracketIndex)
                    dataString = dataString.replacingOccurrences(of: "color: [", with: "")
                }
                // convert the string into an array -- using , as delimeter
                let colorComponentsStringArray = dataString.components(separatedBy: ", ")
                // safely convert the string values into numbers
                guard let redColor = NumberFormatter().number(from: colorComponentsStringArray[0]) else { return }
                guard let greenColor = NumberFormatter().number(from: colorComponentsStringArray[1]) else { return }
                guard let blueColor = NumberFormatter().number(from: colorComponentsStringArray[2]) else { return }
                guard let colorAlpha = NumberFormatter().number(from: colorComponentsStringArray[3]) else { return }
                // set line color to UIColor from remote user
                self.lineColor = UIColor.init(red: CGFloat(truncating: redColor), green: CGFloat(truncating: greenColor), blue: CGFloat(truncating:blueColor), alpha: CGFloat(truncating:colorAlpha))
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
                guard let pointOfView = self.sceneView.pointOfView else { return }
                let transform = pointOfView.transform // transformation matrix
                let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33) // camera rotation
                let location = SCNVector3(transform.m41, transform.m42, transform.m43) // location of camera frustum
                let currentPostionOfCamera = orientation + location // center of frustum in world space
                DispatchQueue.main.async {
                    let touchRootNode : SCNNode = SCNNode() // create an empty node to serve as our root for the incoming points
                    touchRootNode.position = currentPostionOfCamera // place the root node ad the center of the camera's frustum
                    touchRootNode.scale = SCNVector3(1.25, 1.25, 1.25)// touches projected in Z will appear smaller than expected - increase scale of root node to compensate
                    guard let sceneView = self.sceneView else { return }
                    sceneView.scene.rootNode.addChildNode(touchRootNode) // add the root node to the scene
                    let constraint = SCNLookAtConstraint(target: self.sceneView.pointOfView) // force root node to always face the camera
                    constraint.isGimbalLockEnabled = true // enable gimbal locking to avoid issues with rotations from LookAtConstraint
                    touchRootNode.constraints = [constraint] // apply LookAtConstraint

                    self.touchRoots.append(touchRootNode)
                }
            case "touch-end":
                if debug {
                    print("touch-end msg recieved")
                }
            default:
                if debug {
                    print("touch points msg recieved")
                }
                // convert data string into an array -- using given pattern as delimeter
                let arrayOfPoints = dataStr.components(separatedBy: "), (")

                if debug {
                    print("arrayOfPoints: \(arrayOfPoints)")
                }

                for pointString in arrayOfPoints {
                    let pointArray: [String] = pointString.components(separatedBy: ", ")
                    // make sure we have 2 points and convert them from String to number
                    if pointArray.count == 2, let x = NumberFormatter().number(from: pointArray[0]), let y = NumberFormatter().number(from: pointArray[1]) {
                        let remotePoint: CGPoint = CGPoint(x: CGFloat(truncating: x), y: CGFloat(truncating: y))
                        self.remotePoints.append(remotePoint)
                        if debug {
                            print("POINT - \(pointString)")
                            print("CGPOINT: \(remotePoint)")
                        }
                    }
                }
            }
        }
    }
}
