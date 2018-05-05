//
//  Animations.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 11/21/17.
//  Copyright © 2017 Menalto. All rights reserved.
//

import Foundation
import UIKit
    
protocol Animation {
    func animate(view: UIView, completion: @escaping ()->())
}

class Animations {
    static var all: [Animation] = [
        FaceBalls(),
        RollAway(),
        WordPop(),
        FaceBalls()
    ]

    static var random: Animation {
        return all.random!
    }
}
