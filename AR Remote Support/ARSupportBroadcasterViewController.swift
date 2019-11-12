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
import AgoraRtcEngineKit

class ARSupportBroadcasterViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, RenderARDelegate, AgoraRtcEngineDelegate {
    
    var sceneView : ARSCNView!
    var scnLights : [SCNNode] = []
    
    var micBtn: UIButton!
    var remoteVideoView: UIView!
    
    // Agora
    var agoraKit: AgoraRtcEngineKit!
    var channelName: String!
    private let arVideoSource: ARVideoSource = ARVideoSource()
    
    var sessionIsActive = false
    var remoteUser: UInt?
    var dataStreamId: Int! = 27
    var streamIsEnabled: Int32 = -1
    
    // ARVideoKit Renderer - used as an off-screen renderer
    var arvkRenderer: RecordAR!
    
    let debug : Bool = true
    
    // MARK: VC Events
    override func loadView() {
        super.loadView()
        createUI()
        self.view.backgroundColor = UIColor.black
        
        // Agora setup
        guard let appID = getValue(withKey: "AppID", within: "keys") else { return }
        self.agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: appID, delegate: self)
        self.agoraKit.setChannelProfile(.communication)
        let videoConfig = AgoraVideoEncoderConfiguration(size: AgoraVideoDimension840x480, frameRate: .fps15, bitrate: AgoraVideoBitrateStandard, orientationMode: .fixedPortrait)
        self.agoraKit.setVideoEncoderConfiguration(videoConfig)
        self.agoraKit.enableVideo()
        self.agoraKit.setVideoSource(self.arVideoSource)
        self.agoraKit.enableExternalAudioSource(withSampleRate: 44100, channelsPerFrame: 1)
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super .viewWillAppear(animated)
        // Configure ARKit Session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.providesAudioData = true
        configuration.isLightEstimationEnabled = true

        self.sceneView.session.run(configuration)
        self.arvkRenderer?.prepare(configuration)
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set render delegate
        self.sceneView.delegate = self
        self.sceneView.session.delegate = self
        
        // setup ARViewRecorder
        self.arvkRenderer = RecordAR(ARSceneKit: self.sceneView)
        self.arvkRenderer?.renderAR = self // Set the renderer's delegate
        // Configure the renderer to perform additional image & video processing 👁
        self.arvkRenderer?.onlyRenderWhileRecording = false
        // Configure ARKit content mode. Default is .auto
        self.arvkRenderer?.contentMode = .aspectFit
        //record or photo add environment light rendering, Default is false
        self.arvkRenderer?.enableAdjustEnvironmentLighting = true
        // Set the UIViewController orientations
        self.arvkRenderer?.inputViewOrientations = [.portrait]

        if debug {
            self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
            self.sceneView.showsStatistics = true
        }
        
        joinChannel() // Agora - join the channel
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let light = self.createLight(withPosition: SCNVector3(x: 0,y: 5,z: 0), andEulerRotation: SCNVector3(-Float.pi / 2, 0, 0))
        self.sceneView.scene.rootNode.addChildNode(light)
        self.scnLights.append(light)
    }
    
    // MARK: Create UI
    func createUI() {
        // Setup sceneview
        let sceneView = ARSCNView() //instantiate scene view
        self.view.insertSubview(sceneView, at: 0)
        
        //add sceneView layout contstraints
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        sceneView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        sceneView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        sceneView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        sceneView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        // set reference to sceneView
        self.sceneView = sceneView
        
        // add remote video view
        let remoteViewScale = self.view.frame.width * 0.33
        let remoteView = UIView()
        remoteView.frame = CGRect(x: self.view.frame.maxX - (remoteViewScale+15), y: self.view.frame.maxY - (remoteViewScale+25), width: remoteViewScale, height: remoteViewScale)
        remoteView.backgroundColor = UIColor.lightGray
        remoteView.layer.cornerRadius = 25
        remoteView.layer.masksToBounds = true
        self.view.insertSubview(remoteView, at: 1)
        self.remoteVideoView = remoteView
        
        // mic button
        let micBtn = UIButton()
        micBtn.frame = CGRect(x: self.view.frame.midX-37.5, y: self.view.frame.maxY-100, width: 75, height: 75)
        if let imageMicBtn = UIImage(named: "mic") {
            micBtn.setImage(imageMicBtn, for: .normal)
        } else {
            micBtn.setTitle("mute", for: .normal)
        }
        micBtn.addTarget(self, action: #selector(toggleMic), for: .touchDown)
        self.view.insertSubview(micBtn, at: 2)
        self.micBtn = micBtn
        
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
    
    @IBAction func toggleMic() {
        guard let activeMicImg = UIImage(named: "mic") else { return }
        guard let disabledMicImg = UIImage(named: "mute") else { return }
        if self.micBtn.imageView?.image == activeMicImg {
            print("disable active mic")
            self.micBtn.setImage(disabledMicImg, for: .normal)
            self.agoraKit.muteLocalAudioStream(true)
        } else {
            print("enable mic")
            self.micBtn.setImage(activeMicImg, for: .normal)
            self.agoraKit.muteLocalAudioStream(false)
        }
    }
    
    // MARK: Agora Interface
    func joinChannel() {
        // Set audio route to speaker
        self.agoraKit.setDefaultAudioRouteToSpeakerphone(true)
        
        let token = getValue(withKey: "token", within: "keys")
        self.agoraKit.joinChannel(byToken: token, channelId: self.channelName, info: nil, uid: 0) { (channel, uid, elapsed) in
            print("Successfully joined: \(channel), with \(uid): \(elapsed) secongs ago")
        }
        
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    func leaveChannel() {
        // leave channel and end chat
        self.agoraKit.leaveChannel(nil)
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    // MARK: Hide status bar
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: ARVidoeKit Renderer
    func frame(didRender buffer: CVPixelBuffer, with time: CMTime, using rawBuffer: CVPixelBuffer) {
        self.arVideoSource.sendBuffer(buffer, timestamp: time.seconds)
    }
    
    // MARK: Render delegate
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        
        // TODO: Add config option to enable/disable real-world lighting
        guard let currentFrame = self.sceneView.session.currentFrame else { return }
        // change the .intensity property of scene env light to they respond to the real world env
        let intensity : CGFloat = currentFrame.lightEstimate!.ambientIntensity / 1000.0
        self.sceneView.scene.lightingEnvironment.intensity = intensity
        if self.scnLights.count > 0 {
            for node in self.scnLights {
                node.light?.intensity = intensity
            }
        }
        
        guard let pointOfView = self.sceneView.pointOfView else { return }
        let transform = pointOfView.transform // transformation matrix
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33) // camera rotation
        let location = SCNVector3(transform.m41, transform.m42, transform.m43) // camera translation
        
        let currentPostionOfCamera = orientation + location
        DispatchQueue.main.async {
            let sphereNode : SCNNode = SCNNode(geometry: SCNSphere(radius: 0.01))
            sphereNode.position = currentPostionOfCamera // give the user a visual cue of brush position
            sphereNode.name = "brushPointer" // set name to differentiate
//            sphereNode.geometry?.firstMaterial?.diffuse.contents = UIColor.lightGray
            guard let sceneView = self.sceneView else { return }
            sceneView.scene.rootNode.addChildNode(sphereNode)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // do something on render update
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        
    }
    
    // plane detection
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // anchor plane detection
    }
    
    // plane updating
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // anchor plane is updated
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        // anchor plane is removed
    }
    
     // MARK: Session delegate
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        self.arVideoSource.sendBuffer(frame.capturedImage, timestamp: frame.timestamp)
    }
    
    func session(_ session: ARSession, didOutputAudioSampleBuffer audioSampleBuffer: CMSampleBuffer) {
        self.agoraKit.pushExternalAudioFrameSampleBuffer(audioSampleBuffer)
    }
    
    // MARK: AGORA DELEGATE
    func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoDecodedOfUid uid:UInt, size:CGSize, elapsed:Int) {
        if uid == self.remoteUser {
            guard let remoteView = self.remoteVideoView else { return }
            let videoCanvas = AgoraRtcVideoCanvas()
            videoCanvas.uid = uid
            videoCanvas.view = remoteView
            videoCanvas.renderMode = .hidden
            agoraKit.setupRemoteVideo(videoCanvas)
            
            self.sessionIsActive = true
            
            // create the data stream
            self.streamIsEnabled = self.agoraKit.createDataStream(&self.dataStreamId, reliable: true, ordered: true)
            print("Data Stream initiated - STATUS: \(self.streamIsEnabled)")
        }

    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        print("error: \(errorCode.rawValue)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurWarning warningCode: AgoraWarningCode) {
        print("warning: \(warningCode.rawValue)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        print("local user did join channel with uid:\(uid)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("remote user did joined of uid: \(uid)")
        if self.remoteUser == nil {
            self.remoteUser = uid // keep track of the remote user
            print("remote host added")
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        print("remote user did offline of uid: \(uid)")
        if uid == self.remoteUser {
            self.remoteUser = nil
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didAudioMuted muted: Bool, byUid uid: UInt) {
        // add logic to show icon that remote stream is muted
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, receiveStreamMessageFromUid uid: UInt, streamId: Int, data: Data) {
        // successfully received message from user
        print("STREAMID: \(streamId)\n - DATA: \(data)")
        if data.count == MemoryLayout.size(ofValue: CGPoint.self) {
            print("STREAMID: \(streamId)\n - DATA: \(data)")
//            var receivedPoint = UnsafePointer<CGPoint>(data.bytes).memory
        } else {
            // error
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurStreamMessageErrorFromUid uid: UInt, streamId: Int, error: Int, missed: Int, cached: Int) {
        // message failed to send(
        print("STREAMID: \(streamId)\n - ERROR: \(error)")
    }
    
    // MARK: Lights
    func createLight(withPosition position: SCNVector3, andEulerRotation rotation: SCNVector3) -> SCNNode {
        // Create a directional light node with shadow
        let directionalNode : SCNNode = SCNNode()
        directionalNode.light = SCNLight()
        directionalNode.light?.type = SCNLight.LightType.directional
        directionalNode.light?.color = UIColor.white
        directionalNode.light?.castsShadow = true
        directionalNode.light?.automaticallyAdjustsShadowProjection = true
        directionalNode.light?.shadowSampleCount = 64
        directionalNode.light?.shadowRadius = 16
        directionalNode.light?.shadowMode = .deferred
        directionalNode.light?.shadowMapSize = CGSize(width: 1024, height: 1024)
        directionalNode.light?.shadowColor = UIColor.black.withAlphaComponent(0.75)
        directionalNode.position = position
        directionalNode.eulerAngles = rotation
        
        return directionalNode
    }

}

