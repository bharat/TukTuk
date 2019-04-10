//
//  CGPoint.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/10/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import CoreGraphics

func +(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}


extension CGPoint {
    func distance(to point:CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}
