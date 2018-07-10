//
//  Collection.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/5/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation

extension Collection where Index == Int {
    var random: Iterator.Element {
        return self[Int(arc4random_uniform(UInt32(endIndex)))]
    }
}
