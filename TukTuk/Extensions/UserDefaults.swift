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
        case movieCountdown = "movieCountdown"
    }

    func registerDefaults() {
        register(defaults: [
            Key.movieCountdown.rawValue: TimeInterval.MovieInterval
        ])
    }

    var movieCountdown: TimeInterval {
        get {
            return double(forKey: Key.movieCountdown.rawValue)
        }

        set {
            setValue(newValue, forKey: Key.movieCountdown.rawValue)
        }
    }
}
