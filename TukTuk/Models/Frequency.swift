//
//  Frequency.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 9/18/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation

struct Frequency: Titled {
    var seconds: Int

    var title: String {
        return "Every \(seconds / 60) minutes"
    }
}
