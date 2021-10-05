//
//  AgoraSupportAudienceViewController.swift
//  AR Remote Support
//
//  Created by digitallysavvy on 10/30/19.
//  Copyright © 2019 Agora.io. All rights reserved.
//

import UIKit
import AgoraRtcKit
import AgoraUIKit_iOS

class ARSupportAudienceViewController: UIViewController, UIGestureRecognizerDelegate, AgoraRtcEngineDelegate {

    var touchStart: CGPoint!                // keep track of the initial touch point of each gesture
    var touchPoints: [CGPoint]!             // for drawing touches to the screen
    
    //  list of colors that user can choose from
    let uiColors: [UIColor] = [UIColor.systemBlue, UIColor.systemGray, UIColor.systemGreen, UIColor.systemYellow, UIColor.systemRed]
    
    var lineColor: UIColor!                 // active color to use when drawing
    let bgColor: UIColor = .white           // set the view bg color
    
    var drawingView: UIView!                // view to draw all the local touches
    var localVideoView: UIView!             // video stream of local camera
    var remoteVideoView: UIView!            // video stream from remote user
    var micBtn: UIButton!                   // button to mute/un-mute the microphone
    var colorSelectionBtn: UIButton!        // button to handle display or hiding the colors avialble to the user
    var colorButtons: [UIButton] = []       // keep track of the buttons for each color
    
    // Agora
    var agoraView: AgoraVideoViewer!
    var agoraKit: AgoraRtcEngineKit! {      // Agora.io Video Engine reference
        self.agoraView.agkit
    }
    var channelName: String!                // name of the channel to join
     
    var sessionIsActive = false             // keep track if the video session is active or not
    var remoteFeedSize: CGSize?
    var remoteUser: UInt?                   // remote user id
    var dataStreamId: Int! = 27             // id for data stream
    var streamIsEnabled: Int32 = -1         // acts as a flag to keep track if the data stream is enabled
    
    var dataPointsArray: [CGPoint] = []     // batch list of touches to be sent to remote user
    
    let debug: Bool = false                 // toggle the debug logs
    
    // MARK: VC Events
    override func loadView() {
        super.loadView()

        // Add Agora setup
        let appID = AppKeys.appId // getValue(withKey: "AppID", within: "keys") else { return }  // get the AppID from keys.plist
        var agSettings = AgoraSettings()
        agSettings.rtcDelegate = self
        agSettings.showSelf = false
        agSettings.videoConfiguration = AgoraVideoEncoderConfiguration(
            size: AgoraVideoDimension360x360, frameRate: .fps15,
            bitrate: AgoraVideoBitrateStandard, orientationMode: .fixedPortrait
        )
        agSettings.enabledButtons = []
        agSettings.rtmEnabled = false

        self.agoraView = AgoraVideoViewer(
            connectionData: AgoraConnectionData(appId: appID, idLogic: .random), agoraSettings: agSettings
        )
        createUI()
        setupGestures()
        self.view.isUserInteractionEnabled = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.lineColor = self.uiColors.first
        self.view.backgroundColor = self.bgColor
        self.view.isUserInteractionEnabled = true
        // Agora - join the channel
        joinChannel()
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
        if self.sessionIsActive {
            leaveChannel();
        }
    }
    
    // MARK: Hide status bar
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: Gestures
    func setupGestures() {
        // pan gesture
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        self.view.addGestureRecognizer(panGesture)
    }
    
    // MARK: Touch Capture
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       // get the initial touch event
        if self.sessionIsActive, let touch = touches.first {
            let position = touch.location(in: self.view)
            self.touchStart = position
            self.touchPoints = []
            if debug {
                print(position)
            }
        }
        if let colorSelectionBtn = self.colorSelectionBtn, colorSelectionBtn.alpha < 1 {
            toggleColorSelection() // make sure to hide the color menu
        }
    }
    
    @IBAction func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        if self.sessionIsActive && gestureRecognizer.state == .began && self.streamIsEnabled == 0 {
            // send message to remote user that touches have started
//            self.agoraView.rtmController?.sendRaw(message: "touch-start", channel: self.channelName, callback: { messageStatus in
//                if messageStatus != .errorOk {
//                    print("message could not send: \(messageStatus.rawValue)")
//                }
//            })
            self.agoraKit.sendStreamMessage(self.dataStreamId, data: "touch-start".data(using: String.Encoding.ascii)!)
        }
        
        if self.sessionIsActive && (gestureRecognizer.state == .began || gestureRecognizer.state == .changed) {
            let translation = gestureRecognizer.translation(in: self.view)
            // calculate touch movement relative to the superview
            guard let touchStart = self.touchStart else { return } // ignore accidental finger drags
            let pixelTranslation = CGPoint(x: touchStart.x + translation.x, y: touchStart.y + translation.y)
            
            // normalize the touch point to use view center as the reference point
            let translationFromCenter = CGPoint(x: pixelTranslation.x - (0.5 * self.view.frame.width), y: pixelTranslation.y - (0.5 * self.view.frame.height))
            
            self.touchPoints.append(pixelTranslation)
            
            if self.streamIsEnabled == 0 {
                // send data to remote user
                let pointToSend = CGPoint(x: translationFromCenter.x, y: translationFromCenter.y)
                self.dataPointsArray.append(pointToSend)
                if self.dataPointsArray.count == 10 {
                    sendTouchPoints() // send touch data to remote user
                    clearSubLayers() // remove touches drawn to the screen
                }

                if debug {
                    print("streaming data: \(pointToSend)\n - STRING: \(self.dataPointsArray)\n - DATA: \(self.dataPointsArray.description.data(using: String.Encoding.ascii)!)")
                }
            }
            
            DispatchQueue.main.async {
                // draw user touches to the DrawView
                guard let drawView = self.drawingView else { return }
                guard let lineColor: UIColor = self.lineColor else { return }
                let layer = CAShapeLayer()
                layer.path = UIBezierPath(roundedRect: CGRect(x:  pixelTranslation.x, y: pixelTranslation.y, width: 25, height: 25), cornerRadius: 50).cgPath
                layer.fillColor = lineColor.cgColor
                drawView.layer.addSublayer(layer)
            }
            
            if debug {
                print(translationFromCenter)
                print(pixelTranslation)
            }
        }
        
        if gestureRecognizer.state == .ended {
            // send message to remote user that touches have ended
            if self.streamIsEnabled == 0 {
                // transmit any left over points
                if self.dataPointsArray.count > 0 {
                    sendTouchPoints() // send touch data to remote user
                    clearSubLayers() // remove touches drawn to the screen
                }
//                self.agoraView.rtmController?.sendRaw(message: "touch-end", channel: self.channelName, callback: { messageStatus in
//                    if messageStatus != .errorOk {
//                        print("message could not send: \(messageStatus.rawValue)")
//                    }
//                })
                self.agoraKit.sendStreamMessage(self.dataStreamId, data: "touch-end".data(using: String.Encoding.ascii)!)
            }
            // clear list of points
            if let touchPointsList = self.touchPoints {
                self.touchStart = nil // clear starting point
                if debug {
                    print(touchPointsList)
                }
            }
        }
    }
    
    func sendTouchPoints() {
        let pointsAsString: String = self.dataPointsArray.description
//        self.agoraView.rtmController?.sendRaw(message: pointsAsString, channel: self.channelName, callback: { messageStatus in
//            if messageStatus != .errorOk {
//                print("message could not send: \(messageStatus.rawValue)")
//            }
//        })
        self.agoraKit.sendStreamMessage(self.dataStreamId, data: pointsAsString.data(using: String.Encoding.ascii)!)
        self.dataPointsArray = []
    }
    
    func clearSubLayers() {
        DispatchQueue.main.async {
            // loop through layers drawn from touches and remove them from the view
            guard let sublayers = self.drawingView.layer.sublayers else { return }
            for layer in sublayers {
                layer.isHidden = true
                layer.removeFromSuperlayer()
            }
        }
    }
    
    // MARK: UI
    func createUI() {
        
        self.view.insertSubview(self.agoraView, at: 0)
        self.agoraView.translatesAutoresizingMaskIntoConstraints = false
        self.agoraView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.agoraView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.agoraView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.agoraView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true

        
        // ui view that the finger drawings will appear on
        let drawingView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        self.view.insertSubview(drawingView, at: 4)
        self.drawingView = drawingView

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
        backBtn.frame = CGRect(x: self.view.frame.maxX-55, y: self.view.frame.minY+20, width: 30, height: 30)
//        backBtn.layer.cornerRadius = 10
        if let imageExitBtn = UIImage(named: "exit") {
            backBtn.setImage(imageExitBtn, for: .normal)
        } else {
            backBtn.setTitle("x", for: .normal)
        }
        backBtn.addTarget(self, action: #selector(popView), for: .touchUpInside)
        self.view.insertSubview(backBtn, at: 3)
        
        // color palette button
        let colorSelectionBtn = UIButton(type: .custom)
        colorSelectionBtn.frame = CGRect(x: self.view.frame.minX+20, y: self.view.frame.maxY-60, width: 40, height: 40)
        if let colorSelectionBtnImage = UIImage(named: "color") {
            let tinableImage = colorSelectionBtnImage.withRenderingMode(.alwaysTemplate)
            colorSelectionBtn.setImage(tinableImage, for: .normal)
            colorSelectionBtn.tintColor = self.uiColors.first
        } else {
           colorSelectionBtn.setTitle("color", for: .normal)
        }
        colorSelectionBtn.addTarget(self, action: #selector(toggleColorSelection), for: .touchUpInside)
        self.view.insertSubview(colorSelectionBtn, at: 4)
        self.colorSelectionBtn = colorSelectionBtn
        
        // set up color buttons
        for (index, color) in uiColors.enumerated() {
            let colorBtn = UIButton(type: .custom)
            colorBtn.frame = CGRect(x: colorSelectionBtn.frame.midX-13.25, y: colorSelectionBtn.frame.minY-CGFloat(35+(index*35)), width: 27.5, height: 27.5)
            colorBtn.layer.cornerRadius = 0.5 * colorBtn.bounds.size.width
            colorBtn.clipsToBounds = true
            colorBtn.backgroundColor = color
            colorBtn.addTarget(self, action: #selector(setColor), for: .touchDown)
            colorBtn.alpha = 0
            colorBtn.isHidden = true
            colorBtn.isUserInteractionEnabled = false
            self.view.insertSubview(colorBtn, at: 3)
            self.colorButtons.append(colorBtn)
        }
        
        // add undo button
        let undoBtn = UIButton()
        undoBtn.frame = CGRect(x: colorSelectionBtn.frame.maxX+25, y: colorSelectionBtn.frame.minY+5, width: 30, height: 30)
        if let imageUndoBtn = UIImage(named: "undo") {
            undoBtn.setImage(imageUndoBtn, for: .normal)
        } else {
            undoBtn.setTitle("undo", for: .normal)
        }
        undoBtn.addTarget(self, action: #selector(sendUndoMsg), for: .touchUpInside)
        self.view.insertSubview(undoBtn, at: 3)
        
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
            self.micBtn.setImage(disabledMicImg, for: .normal)
            self.agoraKit.muteLocalAudioStream(true)
            self.agoraView.setMic(to: false)
            if debug {
                print("disable active mic")
            }
        } else {
            self.micBtn.setImage(activeMicImg, for: .normal)
            self.agoraView.setMic(to: true)
            if debug {
                print("enable mic")
            }
        }
    }
    
    @IBAction func toggleColorSelection() {
        guard let colorSelectionBtn = self.colorSelectionBtn else { return }
        var isHidden = false
        var alpha: CGFloat = 1
        
        if colorSelectionBtn.alpha == 1 {
            colorSelectionBtn.alpha = 0.65
        } else {
            colorSelectionBtn.alpha = 1
            alpha = 0
            isHidden = true
        }
        
        for button in self.colorButtons {
            // highlihgt the selected color
            button.alpha = alpha
            button.isHidden = isHidden
            button.isUserInteractionEnabled = !isHidden
            // use CGColor in comparison: BackgroundColor and TintColor do not init the same for the same UIColor.
            if button.backgroundColor?.cgColor == colorSelectionBtn.tintColor.cgColor {
                button.layer.borderColor = UIColor.white.cgColor
                button.layer.borderWidth = 2
            } else {
                button.layer.borderWidth = 0
            }
        }

    }
    
    @IBAction func setColor(_ sender: UIButton) {
        guard let colorSelectionBtn = self.colorSelectionBtn else { return }
        colorSelectionBtn.tintColor = sender.backgroundColor
        self.lineColor = colorSelectionBtn.tintColor
        toggleColorSelection()
        // send data message with color components
        if self.streamIsEnabled == 0 {
            guard let colorComponents = sender.backgroundColor?.cgColor.components else { return }
//            self.agoraView.rtmController?.sendRaw(message: "color: \(colorComponents)", channel: self.channelName, callback: { messageStatus in
//                if messageStatus != .errorOk {
//                    print("message could not send: \(messageStatus.rawValue)")
//                }
//            })
            self.agoraKit.sendStreamMessage(self.dataStreamId, data: "color: \(colorComponents)".data(using: String.Encoding.ascii)!)
            if debug {
                print("color: \(colorComponents)")
            }
        }
    }
    
    @IBAction func sendUndoMsg() {
        if self.streamIsEnabled == 0 {
//            self.agoraView.rtmController?.sendRaw(message: "undo", channel: self.channelName, callback: { messageStatus in
//                if messageStatus != .errorOk {
//                    print("message could not send: \(messageStatus.rawValue)")
//                }
//            })
            self.agoraKit.sendStreamMessage(self.dataStreamId, data: "undo".data(using: String.Encoding.ascii)!)
        }
    }
    
    // MARK: Agora Implementation
    func setupLocalVideo(with uid: UInt) {
        guard let localViewRef = self.agoraView.userVideoLookup[uid] else {
            return
        }
        if self.localVideoView == nil {
            let localViewScale = self.view.frame.width * 0.33
            localViewRef.frame = CGRect(x: self.view.frame.maxX - (localViewScale+17.5), y: self.view.frame.maxY - (localViewScale+25), width: localViewScale, height: localViewScale)
            localViewRef.layer.cornerRadius = 25
            localViewRef.layer.masksToBounds = true
            localViewRef.backgroundColor = UIColor.darkGray
            self.view.insertSubview(localViewRef, at: 2)
            self.localVideoView = localViewRef
        }

        guard let videoView = localViewRef.subviews.first else { return }
        videoView.layer.cornerRadius = 25
    }
    
    func joinChannel() {
        // Set audio route to speaker
        self.agoraKit.setDefaultAudioRouteToSpeakerphone(true)
        // get the token - returns nil if no value is set
        let token = AppKeys.token // getValue(withKey: "token", within: "keys")
        // Join the channel
        self.agoraView.join(channel: self.channelName, with: token, as: .broadcaster)
        UIApplication.shared.isIdleTimerDisabled = true     // Disable idle timmer
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.leaveChannel()
    }

    func leaveChannel() {
        self.agoraView.rtmController?.rtmKit.logout()
        self.agoraView.exit()                                  // leave channel and end chat
        self.sessionIsActive = false                        // session is no longer active
        UIApplication.shared.isIdleTimerDisabled = false    // Enable idle timer
    }
    
    // MARK: Agora Delegate
    func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoDecodedOfUid uid:UInt, size:CGSize, elapsed:Int) {
         // first remote video frame
        if self.debug {
            print("firstRemoteVideoDecoded for Uid: \(uid)")
        }
        // limit sessions to two users
        if self.remoteUser == uid {
            self.sessionIsActive = true
            
            // create the data stream
            self.streamIsEnabled = self.agoraKit.createDataStream(&self.dataStreamId, reliable: true, ordered: true)
            self.remoteFeedSize = size
            let feedWidth = self.view.frame.height * size.width / size.height
            self.agoraKit.sendStreamMessage(
                self.dataStreamId, data: "frame-size:[\(feedWidth), \(self.view.frame.height)]".data(using: .ascii)!
            )
//            if self.debug {
//                print("Data Stream initiated - STATUS: \(self.streamIsEnabled)")
//            }
        }

    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        if self.debug {
            print("error: \(errorCode.rawValue)")
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurWarning warningCode: AgoraWarningCode) {
        if self.debug {
            print("222 warning: \(warningCode.rawValue)")
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        if self.debug {
            print("local user did join channel with uid:\(uid)")
        }
//        self.setupLocalVideo(with: uid) //  - set video configuration
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        if self.debug {
            print("remote user did joined of uid: \(uid)")
        }
        if self.remoteUser == nil {
            self.remoteUser = uid // keep track of the remote user
            if self.debug {
                print("remote host added")
            }
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        if self.debug {
            print("remote user did offline of uid: \(uid)")
        }
        if uid == self.remoteUser {
            self.remoteUser = nil
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didAudioMuted muted: Bool, byUid uid: UInt) {
        // add logic to show icon that remote stream is muted
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, receiveStreamMessageFromUid uid: UInt, streamId: Int, data: Data) {
        // successfully received message from user
        if self.debug {
            print("STREAMID: \(streamId)\n - DATA: \(data)")
        }
    }
    
        
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurStreamMessageErrorFromUid uid: UInt, streamId: Int, error: Int, missed: Int, cached: Int) {
        // message failed to send(
        if self.debug {
            print("STREAMID: \(streamId)\n - ERROR: \(error)")
        }
    }

}
