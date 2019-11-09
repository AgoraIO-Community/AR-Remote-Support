//
//  GetValueFromFile.swift
//  AR Remote Support
//
//  Created by Hermes Frangoudis on 11/4/19.
//  Copyright © 2019 Agora.io. All rights reserved.
//

import Foundation

func getValue(withKey keyId:String, within fileName: String) -> String? {
    let filePath = Bundle.main.path(forResource: fileName, ofType: "plist")
    let plist = NSDictionary(contentsOfFile: filePath!)
    guard let value:String = plist?.object(forKey: keyId) as? String else { return nil }
    return value
}
