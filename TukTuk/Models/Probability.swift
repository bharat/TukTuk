//
//  Probability.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 9/20/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation

struct Probability: Titled {
    var denominator: Int

    var title: String {
        return "1 in \(denominator)"
    }

    var outcome: Bool {
        return Array(1...denominator).randomElement()! == 1
    }
}
