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
        case movieFrequency = "movieFrequency"
    }

    func registerDefaults() {
        register(defaults: [
            Key.movieCountdown.rawValue: 2400,
            Key.mazeLevel.rawValue: 1,
            Key.miniGameFrequency.rawValue: 40,
            Key.movieFrequency.rawValue: 2400,
        ])
    }

    var movieCountdown: Int {
        get {
            return integer(forKey: Key.movieCountdown.rawValue)
        }

        set {
            setValue(newValue, forKey: Key.movieCountdown.rawValue)
        }
    }

    var miniGameProbability: Probability {
        get {
            return Probability(denominator: integer(forKey: Key.miniGameFrequency.rawValue))
        }
        set {
            setValue(newValue.denominator, forKey: Key.miniGameFrequency.rawValue)
        }
    }

    var movieFrequency: Frequency {
        get {
            return Frequency(seconds: integer(forKey: Key.movieFrequency.rawValue))
        }
        set {
            setValue(newValue.seconds, forKey: Key.movieFrequency.rawValue)
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
