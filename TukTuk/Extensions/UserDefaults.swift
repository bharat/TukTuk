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
        case mazeComplexity = "mazeComplexity"
    }

    func registerDefaults() {
        register(defaults: [
            Key.movieCountdown.rawValue: TimeInterval.MovieInterval,
            Key.mazeComplexity.rawValue: 3
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

    var mazeComplexity: Int {
        get {
            return integer(forKey: Key.mazeComplexity.rawValue)
        }
        set {
            setValue(newValue, forKey: Key.mazeComplexity.rawValue)
        }
    }
}
