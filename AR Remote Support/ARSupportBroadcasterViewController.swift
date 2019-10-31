//
//  AgoraSupportBroadcasterViewController.swift
//  AR Remote Support
//
//  Created by digitallysavvy on 10/30/19.
//  Copyright © 2019 Agora.io. All rights reserved.
//

import UIKit
import ARKit


class ARSupportBroadcasterViewController: UIViewController, ARSCNViewDelegate {
    
    var sceneView : ARSCNView!
    var scnLights : [SCNNode] = []
    
    let debug : Bool = true
    
    override func loadView() {
        super.loadView()
        
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let light = self.createLight(withPosition: SCNVector3(x: 0,y: 5,z: 0), andEulerRotation: SCNVector3(-Float.pi / 2, 0, 0))
        self.sceneView.scene.rootNode.addChildNode(light)
        self.scnLights.append(light)
    }
    
    // hide the status bar
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // render delegate methods
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        
        // TODO: Add config option to enable/disable real-world lighting
        // change the .intensity property of scene env light to they respond to the real world env
        guard let currentFrame = self.sceneView.session.currentFrame else { return }
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

