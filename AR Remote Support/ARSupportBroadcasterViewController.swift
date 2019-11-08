//
//  AgoraSupportBroadcasterViewController.swift
//  AR Remote Support
//
//  Created by digitallysavvy on 10/30/19.
//  Copyright © 2019 Agora.io. All rights reserved.
//

import UIKit
import ARKit
import AgoraRtcEngineKit

class ARSupportBroadcasterViewController: UIViewController, ARSCNViewDelegate, AgoraRtcEngineDelegate {
    
    var sceneView : ARSCNView!
    var scnLights : [SCNNode] = []
    
    var micBtn: UIButton!
    
    // Agora
    var agoraKit: AgoraRtcEngineKit!
    var channelName: String!
    
    let debug : Bool = true
    
    // MARK: VC Events
    override func loadView() {
        super.loadView()
        createUI()
        self.view.backgroundColor = UIColor.black
        
        // Agora setup
        let appID = getValue(withKey: "AppID", within: "keys")
        self.agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: appID, delegate: self)
        self.agoraKit.setClientRole(.broadcaster)
    }

    override func viewWillAppear(_ animated: Bool) {
        super .viewWillAppear(animated)
        // Configure ARKit Session
        let configuration = ARWorldTrackingConfiguration()
        if #available(iOS 11.3, *) {
            configuration.planeDetection = [.horizontal, .vertical]
        } else {
            // Fallback on earlier versions
            configuration.planeDetection = [.horizontal]
        }
        configuration.isLightEstimationEnabled = true

        self.sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        self.sceneView.session.pause()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set render delegate
        self.sceneView.delegate = self

        if debug {
            self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, .showBoundingBoxes, ARSCNDebugOptions.showFeaturePoints]
            self.sceneView.showsStatistics = true
        }
        
        // Agora - join the channel
        let tokenString = getValue(withKey: "token", within: "keys")
        let token = (tokenString == "") ? nil : tokenString
        self.agoraKit.joinChannel(byToken: token, channelId: self.channelName, info: nil, uid: 0) { (channel, uintID, timeelapsed) in
            print("Successfully joined: \(channel), with \(uintID): \(timeelapsed) secongs ago")
        }
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
        remoteView.frame = CGRect(x: self.view.frame.maxX - (remoteViewScale+17.5), y: self.view.frame.maxY - (remoteViewScale+25), width: remoteViewScale, height: remoteViewScale)
        remoteView.backgroundColor = UIColor.lightGray
        remoteView.layer.cornerRadius = 25
        self.view.insertSubview(remoteView, at: 0)
        
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
    
    @IBAction func popView() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func toggleMic() {
        guard let activeMicImg = UIImage(named: "mic") else { return }
        guard let disabledMicImg = UIImage(named: "mute") else { return }
        if self.micBtn.imageView?.image == activeMicImg {
            print("disable active mic")
            self.micBtn.setImage(disabledMicImg, for: .normal)
        } else {
            print("enable mic")
            self.micBtn.setImage(activeMicImg, for: .normal)
        }
    }
    
    // MARK: Agora Interface
    
    // MARK: Hide status bar
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: Render delegate
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        
        // TODO: Add config option to enable/disable real-world lighting
        guard let currentFrame = self.sceneView.session.currentFrame else { return }
        // change the .intensity property of scene env light to they respond to the real world env
        let intensity : CGFloat = currentFrame.lightEstimate!.ambientIntensity / 1000.0
        self.sceneView.scene.lightingEnvironment.intensity = intensity
        if scnLights.count > 0 {
            for node in scnLights {
                node.light?.intensity = intensity
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // do something on render update
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

