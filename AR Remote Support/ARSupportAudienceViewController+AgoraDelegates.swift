//
//  ARSupportAudienceViewController+AgoraDelegates.swift
//  AR Remote Support
//
//  Created by Max Cobb on 05/10/2021.
//  Copyright © 2021 Agora.io. All rights reserved.
//

import CoreGraphics
import AgoraRtcKit

extension ARSupportAudienceViewController {
    // MARK: Agora Delegate
    func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoDecodedOfUid uid: UInt, size: CGSize, elapsed: Int) {
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
            self.sendMessage("frame-size:[\(feedWidth), \(self.view.frame.height)]")
            if self.debug {
                print("Data Stream initiated - STATUS: \(self.streamIsEnabled)")
            }
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

    // swiftlint:disable:next function_parameter_count
    func rtcEngine(
        _ engine: AgoraRtcEngineKit, didOccurStreamMessageErrorFromUid uid: UInt, streamId: Int,
        error: Int, missed: Int, cached: Int
    ) {
        // message failed to send(
        if self.debug {
            print("STREAMID: \(streamId)\n - ERROR: \(error)")
        }
    }

}
