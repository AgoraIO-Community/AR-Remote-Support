//
//  AgoraSupportAudienceViewController.swift
//  AR Remote Support
//
//  Created by digitallysavvy on 10/30/19.
//  Copyright © 2019 Agora.io. All rights reserved.
//

import UIKit

class ARSupportAudienceViewController: UIViewController, UIGestureRecognizerDelegate {

    var touchStart: CGPoint!
    var touchPoints: [CGPoint]!
    let debug: Bool = true
    
    // MARK: VC Events
    override func loadView() {
        super.loadView()
        createUI()
        setupGestures()
        
        var frame = self.view.frame
        frame.origin.x = self.view.center.x
        frame.origin.y = self.view.center.y
        self.view.frame = frame
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.gray
        self.view.isUserInteractionEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // do something when the view has appeared
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    
    func setupGestures() {
        // pan gesture
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        self.view.addGestureRecognizer(panGesture)
    }
    
    // MARK: Touch Capture
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       // get the initial touch event
        if let touch = touches.first {
            let position = touch.location(in: self.view)
            self.touchStart = position
            let layer = CAShapeLayer()
            layer.path = UIBezierPath(roundedRect: CGRect(x:  position.x, y: position.y, width: 25, height: 25), cornerRadius: 50).cgPath
            layer.fillColor = UIColor.white.cgColor
            self.view.layer.addSublayer(layer)
            self.touchPoints = []
            if debug {
                 print(position)
            }
        }
    }
//
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if let touch = touches.first {
//           let position = touch.location(in: self.view)
//            self.touchPoints.append(position)
//            print(position)
//            let layer = CAShapeLayer()
//            layer.path = UIBezierPath(roundedRect: CGRect(x:  position.x, y: position.y, width: 25, height: 25), cornerRadius: 50).cgPath
//            layer.fillColor = UIColor.white.cgColor
//            self.view.layer.addSublayer(layer)
//        }
//    }
    
    @IBAction func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            let translation = gestureRecognizer.translation(in: self.view)
            // calculate touch movement relative to the superview
            let pixelTranslation = CGPoint(x: self.touchStart.x + translation.x, y: self.touchStart.y + translation.y)
            
            // normalize the touch point to use view center as the reference point
//            let translationFromCenter = CGPoint(x: pixelTranslation.x - (0.5 * self.view.frame.width), y: pixelTranslation.y - (0.5 * self.view.frame.height))
            
//            let pixelTranslationFromCenter = CGPoint(x: 0.5 * self.view.frame.width + translationFromCenter.x, y: 0.5 * self.view.frame.height + translationFromCenter.y)
            
            self.touchPoints.append(pixelTranslation)
            
            // simple draw user touches
            let layer = CAShapeLayer()
            layer.path = UIBezierPath(roundedRect: CGRect(x:  pixelTranslation.x, y: pixelTranslation.y, width: 25, height: 25), cornerRadius: 50).cgPath
            layer.fillColor = UIColor.white.cgColor
            self.view.layer.addSublayer(layer)
            
            if debug {
//                print(translationFromCenter)
                print(pixelTranslation)
               
            }
        }
        if gestureRecognizer.state == .ended {
            if let touchPointsList = self.touchPoints {
                print(touchPointsList)
                // push touch points list to AR View
            }
        }
        
    }
    
    // MARK: UI
    func createUI() {
        //  create button
        let backBtn = UIButton()
        backBtn.frame = CGRect(x: self.view.frame.minX+25, y: self.view.frame.minY + 25, width: 50, height: 50)
        backBtn.backgroundColor = UIColor.systemBlue
        backBtn.layer.cornerRadius = 10
        backBtn.setTitle("back", for: .normal)
        backBtn.addTarget(self, action: #selector(popView), for: .touchUpInside)
        self.view.addSubview(backBtn)
    }
    
    @IBAction func popView() {
        self.dismiss(animated: true, completion: nil)
    }

}
