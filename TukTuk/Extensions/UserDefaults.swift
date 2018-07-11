//
//  UserDefaults.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 7/10/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation

extension String {
    static let videoCountdownKey = "videoCountdown"
}

extension UserDefaults {
    static var videoCountdown: TimeInterval {
        set {
            standard.setValue(newValue, forKey: .videoCountdownKey)
            standard.synchronize()
        }

        get {
            return standard.double(forKey: .videoCountdownKey)
        }
    }
}
