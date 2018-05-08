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
    static var title: String { get }

    init()
    func animate(view: UIView, completion: @escaping ()->())
}

class Animations {
    static var all: [Animation.Type] = [
        Hinge.self,
        RollAway.self,
        WordPop.self,
        FaceBalls.self
    ]

    static var random: Animation {
        return all.random!.init()
    }
}
