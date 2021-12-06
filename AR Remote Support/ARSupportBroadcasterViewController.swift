//
//  AgoraSupportBroadcasterViewController.swift
//  AR Remote Support
//
//  Created by digitallysavvy on 10/30/19.
//  Copyright © 2019 Agora.io. All rights reserved.
//

import UIKit
import ARKit
import ARVideoKit
import AgoraRtcKit
import AgoraUIKit_iOS
import AgoraRtmKit
import SCNLine

class ARSupportBroadcasterViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    var sceneView: ARSCNView!                          // AR SceneView

    var micBtn: UIButton!                               // button to mute/un-mute the microphone
//    var remoteVideoView: UIView!                        // video stream from remote user
    var lineColor: UIColor = UIColor.systemBlue         // color to use when drawing

    // Agora
    var agoraView: AgoraVideoViewer!
    var agoraKit: AgoraRtcEngineKit! {                  // Agora.io Video Engine reference
        self.agoraView.agkit
    }
    var channelName: String!                           // name of the channel to join
//    let arVideoSource: ARVideoSource = ARVideoSource() // for passing the AR camera as the stream

    var sessionIsActive = false                        // keep track if the video session is active or not
    var remoteUser: UInt?                              // remote user id
    var rtmIsConnected: Bool {                         // acts as a flag to keep track if RTM is connected
        switch self.agoraView.rtmStatus {
        case .connected: return true
        default: return false
        }
    }

    var remotePoints: [CGPoint] = []                   // list of touches received from the remote user
    var drawableMult: CGFloat = 1
    var touchRoots: [SCNLineNode] = []                 // list of root nodes for each set of touches drawn - for undo

    var arvkRenderer: RecordAR!                        // ARVideoKit Renderer - used as an off-screen renderer
    #if DEBUG
    let debug: Bool = true                             // toggle the debug logs
    #else
    let debug: Bool = false
    #endif
    var cameraFrameNode = SCNNode(geometry: SCNFloor())
    // MARK: VC Events
    override func loadView() {
        super.loadView()

        // Agora setup
        let connectionData = AgoraConnectionData(appId: AppKeys.appId, appToken: AppKeys.rtcToken, idLogic: .random)
        var agSettings = AgoraSettings()
        agSettings.externalVideoSettings = AgoraSettings.ExternalVideoSettings(
            enabled: true, texture: true, encoded: false
        )
        // Do not show own camera feed
        agSettings.showSelf = false
        // Only enable camera and microphone buttons
        agSettings.enabledButtons = [.cameraButton, .micButton]
        // Set Agora RTC delegate
        agSettings.rtcDelegate = self
        // Set Agora RTM delegate
        agSettings.rtmChannelDelegate = self
        self.agoraView = AgoraVideoViewer(connectionData: connectionData, style: .collection, agoraSettings: agSettings)
    }

    override func viewWillAppear(_ animated: Bool) {
        super .viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // stop the ARVideoKit renderer
        arvkRenderer.rest()
        // Pause the view's session
        self.sceneView.session.pause()
        self.sceneView.removeFromSuperview()
        self.sceneView = nil
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.leaveChannel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.black

        self.agoraView.fills(view: self.view)

        self.joinChannel() // Agora - join the channel

        self.createUI()

        self.setupARView()
        // set render delegate
//        self.sceneView.delegate = self
        self.sceneView.session.delegate = self
    }
    func setupARView() {
        self.sceneView = ARSCNView()
        let node = SCNNode(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.3))
        node.position.z = -3
        self.sceneView.scene.rootNode.addChildNode(node)
        self.view.addSubview(self.sceneView)
        self.view.sendSubviewToBack(self.sceneView)
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        sceneView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        sceneView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        sceneView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        sceneView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true

        // setup ARViewRecorder
        self.arvkRenderer = RecordAR(ARSceneKit: self.sceneView)
        self.arvkRenderer?.renderAR = self // Set the renderer's delegate
        // Configure the renderer to always render the scene
        self.arvkRenderer?.onlyRenderWhileRecording = false
        // Configure ARKit content mode. Default is .auto
        self.arvkRenderer?.contentMode = .aspectFill
        // Set the UIViewController orientations
        self.arvkRenderer?.inputViewOrientations = [.portrait, .landscapeLeft, .landscapeRight]
        self.arvkRenderer?.enableAudio = false

        if debug {
//            self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
//            self.sceneView.showsStatistics = true
        }
        cameraFrameNode.isHidden = true
        self.sceneView.pointOfView?.addChildNode(cameraFrameNode)
        cameraFrameNode.position.z = -1
        cameraFrameNode.eulerAngles.x = -.pi / 2
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Configure ARKit Session
        let configuration = ARWorldTrackingConfiguration()
//        configuration.planeDetection = [.horizontal, .vertical]
//        configuration.providesAudioData = true
        configuration.isLightEstimationEnabled = false

        self.sceneView.session.run(configuration)
        self.arvkRenderer?.prepare(configuration)
    }

    // MARK: Hide status bar
    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: UI
    func createUI() {
        //  back button
        let backBtn = UIButton()
        backBtn.frame = CGRect(x: self.view.frame.maxX-55, y: self.view.frame.minY + 20, width: 30, height: 30)
        backBtn.layer.cornerRadius = 10
        if let imageExitBtn = UIImage(named: "exit") {
            backBtn.setImage(imageExitBtn, for: .normal)
        } else {
            backBtn.setTitle("x", for: .normal)
        }
        backBtn.addTarget(self, action: #selector(popView), for: .touchUpInside)
        self.view.insertSubview(backBtn, at: 2)
    }

    // MARK: Button Events
    @IBAction func popView() {
        leaveChannel()
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: Agora Interface
    func joinChannel() {
        // Set audio route to speaker

        let token = AppKeys.rtcToken // getValue(withKey: "token", within: "keys")
        // get the token - returns nil if no value is set
        // Join the channel
        self.agoraView.join(channel: self.channelName, with: token, as: .broadcaster)

        UIApplication.shared.isIdleTimerDisabled = true     // Disable idle timmer
    }

    func leaveChannel() {
        // leave rtm channel and log out
        self.agoraView.rtmController?.rtmKit.logout()
        // leave channel and end chat
        self.agoraView.exit()
        // session is no longer active
        self.sessionIsActive = false
        // Enable idle timer
        UIApplication.shared.isIdleTimerDisabled = false
    }

    // MARK: Session delegate
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // if we have points - draw 3 points per frame
        DispatchQueue.main.async {
            guard let touchRootNode = self.touchRoots.last else { return }
            var lastPoint = touchRootNode.points.last
            var drawnPoints = 0
            while self.remotePoints.count > 0, drawnPoints < 3 {
                let remotePoint: CGPoint = self.remotePoints.removeFirst() // pop the first node every frame
                print(self.drawableMult)
                let htFloor = self.sceneView.hitTest(.init(
                    x: (remotePoint.x + self.view.frame.width / 2),
                    y: (remotePoint.y + self.view.frame.height / 2)
                ), options: [.ignoreHiddenNodes: false])
                guard let touchedPoint = htFloor.first?.worldCoordinates else { return }
                if let lastPoint = lastPoint, touchedPoint.distance(to: lastPoint) < 0.001 {
                    if self.debug { print("not adding point") }
                } else {
                    touchRootNode.add(point: touchedPoint)
                    drawnPoints += 1
                }
                lastPoint = touchedPoint
            }
        }
    }

    func session(_ session: ARSession, didOutputAudioSampleBuffer audioSampleBuffer: CMSampleBuffer) {
//        self.agoraKit.pushExternalAudioFrameSampleBuffer(audioSampleBuffer)
    }

    // MARK: Lights
    func createLight(withPosition position: SCNVector3, andEulerRotation rotation: SCNVector3) -> SCNNode {
        // Create a directional light node with shadow
        let directionalNode: SCNNode = SCNNode()
        directionalNode.light = SCNLight()
        directionalNode.light?.type = SCNLight.LightType.directional
        directionalNode.light?.color = UIColor.white
        directionalNode.light?.castsShadow = true
        directionalNode.light?.automaticallyAdjustsShadowProjection = true
        directionalNode.light?.shadowSampleCount = 64
        directionalNode.light?.shadowRadius = 16
        directionalNode.light?.shadowMode = .deferred
        directionalNode.light?.shadowMapSize = CGSize(width: 1024, height: 1024)
        directionalNode.light?.shadowColor = UIColor.black.withAlphaComponent(0.5)
        directionalNode.position = position
        directionalNode.eulerAngles = rotation

        return directionalNode
    }

}

extension ARSupportBroadcasterViewController: RenderARDelegate {
    // MARK: ARVidoeKit Renderer
    open func frame(didRender buffer: CVPixelBuffer, with time: CMTime, using rawBuffer: CVPixelBuffer) {
        let videoFrame = AgoraVideoFrame()
        videoFrame.format = 12
        videoFrame.textureBuf = buffer
        videoFrame.time = time
        self.agoraKit.pushExternalVideoFrame(videoFrame)
    }
}
