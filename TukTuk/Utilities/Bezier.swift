//
//  Bezier.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 4/10/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit

class Bezier {
    static func curveFrom(points: [CGPoint]) -> UIBezierPath {
        let cubicCurveAlgorithm = CubicCurveAlgorithm()

        let controlPoints = cubicCurveAlgorithm.controlPointsFromPoints(dataPoints: points)
        let path = UIBezierPath()

        for (i, point) in points.enumerated() {
            if i == 0 {
                path.move(to: point)
            } else {
                let segment = controlPoints[i-1]
                path.addCurve(to: point, controlPoint1: segment.controlPoint1, controlPoint2: segment.controlPoint2)
            }
        }
        return path
    }
}
