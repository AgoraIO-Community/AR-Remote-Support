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
    let debug: Bool = true
    
    // MARK: VC Events
    override func loadView() {
        super.loadView()
        createUI()
        setupGestures()
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
            let position = touch.location(in: view)
            touchStart = position
            if debug {
                 print(position)
            }
        }
    }
    
    @IBAction func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            let translation = gestureRecognizer.translation(in: self.view)
            // calculate touch movement relative to the superview
            let pixelTranslation = CGPoint(x: touchStart.x + translation.x, y: touchStart.y + translation.y)
            
            // simple draw user touches
            let layer = CAShapeLayer()
            layer.path = UIBezierPath(roundedRect: CGRect(x:  pixelTranslation.x, y: pixelTranslation.y, width: 25, height: 25), cornerRadius: 50).cgPath
            layer.fillColor = UIColor.white.cgColor
            self.view.layer.addSublayer(layer)
            
            if debug {
                print(pixelTranslation)
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
