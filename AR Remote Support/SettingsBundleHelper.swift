//
//  SettingsBundleHelper.swift
//  AR Remote Support
//
//  Created by Max Cobb on 01/11/2021.
//  Copyright © 2021 Agora.io. All rights reserved.
//

import Foundation

class SettingsBundleHelper {
    struct SettingsBundleKeys {
        static let AgoraAppId = "agora_id"
        static let AgoraRtcToken = "agora_rtctoken"
        static let AgoraRtmToken = "agora_rtmtoken"
    }

    class func startupCheckSettings() {
        if let keyStr = UserDefaults.standard.string(forKey: SettingsBundleKeys.AgoraAppId), !keyStr.isEmpty {
            AppKeys.appId = keyStr
        }
        if let tokenStr = UserDefaults.standard.string(forKey: SettingsBundleKeys.AgoraRtmToken), !tokenStr.isEmpty {
            AppKeys.rtmToken = tokenStr
        }
        if let tokenStr = UserDefaults.standard.string(forKey: SettingsBundleKeys.AgoraRtcToken), !tokenStr.isEmpty {
            AppKeys.rtcToken = tokenStr
        }
    }

}
