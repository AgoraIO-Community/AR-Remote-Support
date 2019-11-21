//
//  ViewController.swift
//  AR Remote Support
//
//  Created by digitallysavvy on 10/30/19.
//  Copyright © 2019 Agora.io. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {
    
    var channelInput: UITextField!
    var joinButton: UIButton!
    var createButton: UIButton!
    let debug : Bool = false
    
    // MARK: VC Events
    override func loadView() {
        super.loadView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        createUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // dismiss the keyboard when user touches the view
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }
    
    // MARK: Create UI
    func createUI() {
        
        // add branded logo to remote view
        guard let agoraLogo = UIImage(named: "ar-support-icon") else { return }
        let splashLogo = UIImageView(image: agoraLogo)
        splashLogo.frame = CGRect(x: self.view.center.x-100, y: self.view.center.y-275, width: 200, height: 200)
//        splashLogo.alpha = 0.25
        self.view.insertSubview(splashLogo, at: 1)
        
        // text input field
        let textField = UITextField()
        textField.frame = CGRect(x: self.view.center.x-150, y: self.view.center.y-40, width: 300, height: 40)
        textField.placeholder = "Channel Name"
        textField.font = UIFont.systemFont(ofSize: 15)
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        textField.autocorrectionType = UITextAutocorrectionType.no
        textField.keyboardType = UIKeyboardType.default
        textField.returnKeyType = UIReturnKeyType.done
        textField.clearButtonMode = UITextField.ViewMode.whileEditing;
        textField.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        textField.delegate = self
        self.view.addSubview(textField)
        channelInput = textField

        //  create button
        let createBtn = UIButton()
        createBtn.frame = CGRect(x: textField.frame.midX+12.5, y: textField.frame.maxY + 20, width: 100, height: 50)
        createBtn.backgroundColor = UIColor.systemBlue
        createBtn.layer.cornerRadius = 5
        createBtn.setTitle("Create", for: .normal)
        createBtn.addTarget(self, action: #selector(createSession), for: .touchUpInside)
        self.view.addSubview(createBtn)
        
        // add the join button
        let joinBtn = UIButton()
        joinBtn.frame = CGRect(x: createBtn.frame.minX-125, y: createBtn.frame.minY, width: 100, height: 50)
        joinBtn.backgroundColor = UIColor.systemGray
        joinBtn.layer.cornerRadius = 5
        joinBtn.setTitle("Join", for: .normal)
        joinBtn.addTarget(self, action: #selector(joinRemoteSession), for: .touchUpInside)
        self.view.addSubview(joinBtn)
    }
    
    // MARK: Button Actions
    @IBAction func joinRemoteSession() {
        let arSupportVC = ARSupportAudienceViewController()
        if let channelName = self.channelInput.text {
            if channelName != "" {
                arSupportVC.channelName = channelName
                arSupportVC.modalPresentationStyle = .fullScreen
                self.present(arSupportVC, animated: true, completion: nil)
            } else {
               // TODO: add visible msg to user
               print("unable to join a broadcast without an empty channelName")
            }
        }
    }
    
    @IBAction func createSession() {
        let arBroadcastVC = ARSupportBroadcasterViewController()
        if let channelName = self.channelInput.text {
            if channelName != "" {
                arBroadcastVC.channelName = channelName
                arBroadcastVC.modalPresentationStyle = .fullScreen
                self.present(arBroadcastVC, animated: true, completion: nil)
            } else {
               // TODO: add visible msg to user
               print("unable to launch a broadcast without an empty channelName")
            }
        }
    }
    
    // MARK: Textfield Delegates
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if debug {
            print("TextField did begin editing method called")
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if debug {
            print("TextField did end editing method called")
        }
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if debug {
            print("TextField should begin editing method called")
        }
        return true;
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if debug {
            print("TextField should clear method called")
        }
        return true;
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if debug {
            print("TextField should snd editing method called")
        }
        return true;
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if debug {
            print("While entering the characters this method gets called")
        }
        return true;
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if debug {
            print("TextField should return method called")
        }
        textField.resignFirstResponder();
        return true;
    }
}
