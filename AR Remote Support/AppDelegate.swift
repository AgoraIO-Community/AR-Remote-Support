//
//  AppDelegate.swift
//  AR Remote Support
//
//  Created by Hermes Frangoudis on 10/30/19.
//  Copyright © 2019 Agora.io. All rights reserved.
//

import UIKit
import ARVideoKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return ViewAR.orientation
    }


}

