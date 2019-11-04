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
    let lineColor: CGColor = UIColor.gray.cgColor
    let bgColor: UIColor = .white
    let debug: Bool = true
    
    // MARK: VC Events
    override func loadView() {
        super.loadView()
        createUI()
        setupGestures()
        
//        var frame = self.view.frame
//        frame.origin.x = self.view.center.x
//        frame.origin.y = self.view.center.y
//        self.view.frame = frame
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = self.bgColor
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
    
    // MARK: Hide status bar
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: Touch Capture
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       // get the initial touch event
        if let touch = touches.first {
            let position = touch.location(in: self.view)
            self.touchStart = position
            let layer = CAShapeLayer()
            layer.path = UIBezierPath(roundedRect: CGRect(x:  position.x, y: position.y, width: 25, height: 25), cornerRadius: 50).cgPath
            layer.fillColor = self.lineColor
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
            guard let touchStart = self.touchStart else { return }
            let pixelTranslation = CGPoint(x: touchStart.x + translation.x, y: touchStart.y + translation.y)
            
            // normalize the touch point to use view center as the reference point
//            let translationFromCenter = CGPoint(x: pixelTranslation.x - (0.5 * self.view.frame.width), y: pixelTranslation.y - (0.5 * self.view.frame.height))
            
//            let pixelTranslationFromCenter = CGPoint(x: 0.5 * self.view.frame.width + translationFromCenter.x, y: 0.5 * self.view.frame.height + translationFromCenter.y)
            
            self.touchPoints.append(pixelTranslation)
            
            // simple draw user touches
            let layer = CAShapeLayer()
            layer.path = UIBezierPath(roundedRect: CGRect(x:  pixelTranslation.x, y: pixelTranslation.y, width: 25, height: 25), cornerRadius: 50).cgPath
            layer.fillColor = self.lineColor
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
                self.touchStart = nil
            }
        }
        
    }
    
    // MARK: UI
    func createUI() {
        
        // mute button
        let micBtn = UIButton()
        micBtn.frame = CGRect(x: self.view.frame.midX-37.5, y: self.view.frame.maxY-100, width: 75, height: 75)
        if let imageMicBtn = UIImage(named: "mic") {
            micBtn.setImage(imageMicBtn, for: .normal)
        } else {
            micBtn.setTitle("mute", for: .normal)
        }
        self.view.addSubview(micBtn)
        
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
        self.view.addSubview(backBtn)
    }
    
    @IBAction func popView() {
        self.dismiss(animated: true, completion: nil)
    }

}
