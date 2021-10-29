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
    let uiColors: [UIColor] = [
        .systemBlue, .systemGray, .systemGreen, .systemYellow, .systemRed
    ]

    var lineColor: UIColor!                 // active color to use when drawing
    let bgColor: UIColor = .systemBackground// set the view bg color

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
    var rtmIsConnected: Bool {              // acts as a flag to keep track if RTM is connected
        switch self.agoraView.rtmStatus {
        case .connected: return true
        default: return false
        }
    }

    var dataPointsArray: [CGPoint] = []     // batch list of touches to be sent to remote user

    let debug: Bool = false                 // toggle the debug logs

    // MARK: VC Events
    override func loadView() {
        super.loadView()

        // Add Agora setup
        let appID = AppKeys.appId
        var agSettings = AgoraSettings()
        // Set Agora RTC delegate
        agSettings.rtcDelegate = self
        // Do not show own camera feed
        agSettings.showSelf = false
        // Hide all builtin buttons, we will use our own button
        agSettings.enabledButtons = []

        self.agoraView = AgoraVideoViewer(
            connectionData: AgoraConnectionData(appId: appID),
            agoraSettings: agSettings
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        createUI()
        setupGestures()

        self.lineColor = self.uiColors.first
        self.view.backgroundColor = self.bgColor
        self.view.isUserInteractionEnabled = true
        // Agora - join the channel
        joinChannel()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.sessionIsActive {
            leaveChannel()
        }
    }

    // MARK: Hide status bar
    override var prefersStatusBarHidden: Bool { true }

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
        guard self.rtmIsConnected else {
            print("RTM is not connected")
            return
        }
        if self.sessionIsActive && gestureRecognizer.state == .began {
            // send message to remote user that touches have started
            self.sendMessage("touch-start")
        }

        if self.sessionIsActive && (gestureRecognizer.state == .began || gestureRecognizer.state == .changed) {
            let translation = gestureRecognizer.translation(in: self.view)
            // calculate touch movement relative to the superview
            guard let touchStart = self.touchStart else { return } // ignore accidental finger drags
            let mainViewSpace = self.agoraView.backgroundVideoHolder
            let pixelTranslation = CGPoint(x: touchStart.x + translation.x, y: touchStart.y + translation.y)

            // normalize the touch point to use view center as the reference point
            let translationFromCenter = CGPoint(
                x: pixelTranslation.x - (0.5 * mainViewSpace.frame.width),
                y: pixelTranslation.y - mainViewSpace.frame.minY - (0.5 * mainViewSpace.frame.height)
            )

            self.touchPoints.append(pixelTranslation)

            // send data to remote user
            let point = CGPoint(x: translationFromCenter.x, y: translationFromCenter.y)
            self.sendTouchData(touchPoint: point)

            DispatchQueue.main.async {
                // draw user touches to the DrawView
                guard let drawView = self.drawingView else { return }
                guard let lineColor: UIColor = self.lineColor else { return }
                let layer = CAShapeLayer()
                layer.path = UIBezierPath(
                    roundedRect: CGRect(x: pixelTranslation.x, y: pixelTranslation.y, width: 25, height: 25),
                    cornerRadius: 50
                ).cgPath
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
            self.sendTouchEnded()
        }
    }
    func sendTouchEnded() {
        if self.rtmIsConnected {
            // transmit any left over points
            if self.dataPointsArray.count > 0 {
                sendTouchPoints() // send touch data to remote user
                clearSubLayers() // remove touches drawn to the screen
            }
            self.sendMessage("touch-end")
        }
        // clear list of points
        if let touchPointsList = self.touchPoints {
            self.touchStart = nil // clear starting point
            if debug {
                print(touchPointsList)
            }
        }
    }

    func sendTouchData(touchPoint: CGPoint) {
        self.dataPointsArray.append(touchPoint)
        if self.dataPointsArray.count == 10 {
            sendTouchPoints() // send touch data to remote user
            clearSubLayers() // remove touches drawn to the screen
        }

        if debug {
            print("""
                streaming data: \(touchPoint)
                - STRING: \(self.dataPointsArray)
                - DATA: \(self.dataPointsArray.description.data(using: String.Encoding.ascii)!)
            """)
        }

    }

    func sendMessage(_ message: String) {
        if self.rtmIsConnected {
            self.agoraView.rtmController?.sendRaw(
                message: message, channel: self.channelName
            ) { messageStatus in
                if messageStatus != .errorOk {
                    print("message could not send: \(messageStatus.rawValue)")
                }
            }
        } else {
            print("Could not send RTM Message: not connected")
        }
    }

    func sendTouchPoints() {
        let pointsAsString: String = self.dataPointsArray.description
        self.sendMessage(pointsAsString)
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
        // add branded logo to remote view
        guard let agoraLogo = UIImage(named: "agora-logo") else { return }
        let remoteViewBagroundImage = UIImageView(image: agoraLogo)
        self.view.insertSubview(remoteViewBagroundImage, at: 0)
        remoteViewBagroundImage.translatesAutoresizingMaskIntoConstraints = false
        remoteViewBagroundImage.contentMode = .scaleAspectFit
        [remoteViewBagroundImage.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
         remoteViewBagroundImage.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
         remoteViewBagroundImage.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.6),
         remoteViewBagroundImage.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.6)
        ].forEach { $0.isActive = true }
        remoteViewBagroundImage.alpha = 0.25

        self.view.insertSubview(self.agoraView, at: 1)
        self.agoraView.translatesAutoresizingMaskIntoConstraints = false
        self.agoraView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.agoraView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.agoraView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.agoraView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.addButtonsAndGestureViews()
    }

    // MARK: Button Events
    @IBAction func popView() {
        leaveChannel()
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: Agora Implementation

    func joinChannel() {
        // Set audio route to speaker
        self.agoraKit.setDefaultAudioRouteToSpeakerphone(true)
        // get the token
        let token = AppKeys.token
        // Join the channel
        self.agoraView.join(channel: self.channelName, with: token, as: .broadcaster)
        UIApplication.shared.isIdleTimerDisabled = true     // Disable idle timmer
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.leaveChannel()
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
}
