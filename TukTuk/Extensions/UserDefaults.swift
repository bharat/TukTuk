//
//  UserDefaults.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 7/10/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation

extension UserDefaults {
    enum Key: String {
        case videoCountdown = "videoCountdown"
    }

    func registerDefaults() {
        register(defaults: [
            Key.videoCountdown.rawValue: TimeInterval.VideoInterval
        ])
    }

    var videoCountdown: TimeInterval {
        get {
            return double(forKey: Key.videoCountdown.rawValue)
        }

        set {
            setValue(newValue, forKey: Key.videoCountdown.rawValue)
        }
    }
}
