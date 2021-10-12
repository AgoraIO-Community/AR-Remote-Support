//
//  ARSupportAudienceViewController+Buttons.swift
//  AR Remote Support
//
//  Created by Max Cobb on 05/10/2021.
//  Copyright © 2021 Agora.io. All rights reserved.
//

import UIKit

extension ARSupportAudienceViewController {
    func addMicButon() {
        let micBtn = UIButton()
        micBtn.frame = CGRect(x: self.view.frame.midX-37.5, y: self.view.frame.maxY-100, width: 75, height: 75)
        if let imageMicBtn = UIImage(named: "mic") {
            micBtn.setImage(imageMicBtn, for: .normal)
        } else {
            micBtn.setTitle("mute", for: .normal)
        }
        micBtn.addTarget(self, action: #selector(toggleMic), for: .touchDown)
        self.view.insertSubview(micBtn, at: 4)
        self.micBtn = micBtn
    }

    func addBackButton() {
        let backBtn = UIButton()
        backBtn.frame = CGRect(x: self.view.frame.maxX-55, y: self.view.frame.minY+20, width: 30, height: 30)
        if let imageExitBtn = UIImage(named: "exit") {
            backBtn.setImage(imageExitBtn, for: .normal)
        } else {
            backBtn.setTitle("x", for: .normal)
        }
        backBtn.addTarget(self, action: #selector(popView), for: .touchUpInside)
        self.view.insertSubview(backBtn, at: 3)
    }

    func addButtonsAndGestureViews() {
        // ui view that the finger drawings will appear on
        let drawingView = UIView(frame: CGRect(
            x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        )
        self.view.insertSubview(drawingView, at: 2)
        self.drawingView = drawingView

        // mic button
        self.addMicButon()

        //  back button
        self.addBackButton()

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
        self.view.insertSubview(colorSelectionBtn, at: 5)
        self.colorSelectionBtn = colorSelectionBtn

        // set up color buttons
        for (index, color) in uiColors.enumerated() {
            let colorBtn = UIButton(type: .custom)
            colorBtn.frame = CGRect(
                x: colorSelectionBtn.frame.midX-13.25,
                y: colorSelectionBtn.frame.minY-CGFloat(35+(index*35)),
                width: 27.5,
                height: 27.5
            )
            colorBtn.layer.cornerRadius = 0.5 * colorBtn.bounds.size.width
            colorBtn.clipsToBounds = true
            colorBtn.backgroundColor = color
            colorBtn.addTarget(self, action: #selector(setColor), for: .touchDown)
            colorBtn.alpha = 0
            colorBtn.isHidden = true
            colorBtn.isUserInteractionEnabled = false
            self.view.insertSubview(colorBtn, at: 5)
            self.colorButtons.append(colorBtn)
        }

        // add undo button
        self.addUndoButton()
    }

    func addUndoButton() {
        let undoBtn = UIButton()
        undoBtn.frame = CGRect(
            x: colorSelectionBtn.frame.maxX+25, y: colorSelectionBtn.frame.minY+5,
            width: 30, height: 30
        )
        if let imageUndoBtn = UIImage(named: "undo") {
            undoBtn.setImage(imageUndoBtn, for: .normal)
        } else {
            undoBtn.setTitle("undo", for: .normal)
        }
        undoBtn.addTarget(self, action: #selector(sendUndoMsg), for: .touchUpInside)
        self.view.insertSubview(undoBtn, at: 3)
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
            self.sendMessage("color: \(colorComponents)")
            if debug {
                print("color: \(colorComponents)")
            }
        }
    }

    @IBAction func sendUndoMsg() {
        if self.streamIsEnabled == 0 {
            self.sendMessage("undo")
        }
    }

}
