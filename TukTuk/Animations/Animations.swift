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
    var title: String { get }
    func animate(view: UIView, completion: @escaping ()->())
}

class Animations {

    // TODO: change this to Animation.Type so that we're not initializing all of them needlessly
    static var all: [Animation] = [
        Hinge(),
        RollAway(),
        WordPop(),
        FaceBalls()
    ]

    static var random: Animation {
        return all.random!
    }
}
