//
//  ARVideoSource.swift
//  Agora-Video-With-ARKit
//
//  Created by GongYuhua on 2018/1/11.
//  Copyright © 2018 Agora. All rights reserved.
//

import UIKit
import AgoraRtcKit

public class ARVideoSource: NSObject, AgoraVideoSourceProtocol {
    public func captureType() -> AgoraVideoCaptureType { .camera }

    public func contentHint() -> AgoraVideoContentHint { .none }

    public var consumer: AgoraVideoFrameConsumer?
    public var rotation: AgoraVideoRotation = .rotationNone

    public func shouldInitialize() -> Bool { return true }

    public func shouldStart() { }

    public func shouldStop() { }

    public func shouldDispose() { }

    public func bufferType() -> AgoraVideoBufferType {
        return .pixelBuffer
    }

    func sendBuffer(_ buffer: CVPixelBuffer, timestamp: TimeInterval) {
        let time = CMTime(seconds: timestamp, preferredTimescale: 1000)
        let currentOrientation = UIDevice.current.orientation
        var pbRotation: AgoraVideoRotation
        switch currentOrientation {
        case .portrait:
            pbRotation = .rotationNone
        case .portraitUpsideDown:
            pbRotation = .rotation180
        case .landscapeLeft:
            pbRotation = .rotation270
        case .landscapeRight:
            pbRotation = .rotation90
        default:
            pbRotation = .rotationNone
        }
        consumer?.consumePixelBuffer(buffer, withTimestamp: time, rotation: pbRotation)
    }
}
