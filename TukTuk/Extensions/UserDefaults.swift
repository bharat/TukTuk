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
        case mazeLevel = "mazeLevel"
        case miniGameFrequency = "miniGameFrequency"
    }

    func registerDefaults() {
        register(defaults: [
            Key.movieCountdown.rawValue: TimeInterval.MovieInterval,
            Key.mazeLevel.rawValue: 1,
            Key.miniGameFrequency.rawValue: 40,
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

    var miniGameFrequency: Frequency {
        get {
            return Frequency(period: integer(forKey: Key.miniGameFrequency.rawValue))
        }
        set {
            setValue(newValue.period, forKey: Key.miniGameFrequency.rawValue)
        }
    }

    var mazeLevel: Int {
        get {
            return integer(forKey: Key.mazeLevel.rawValue)
        }
        set {
            setValue(newValue, forKey: Key.mazeLevel.rawValue)
        }
    }
}
