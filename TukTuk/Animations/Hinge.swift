//
//  Hinge.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/5/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit

class Hinge: Animation {
    static var title: String = "Hinge"

    required init() {
    }

    func animate(view: UIView, completion: @escaping ()->()) {
        AudioPlayer.instance.play(Sounds.Welcome)

        // Animate away the welcome image. Shrink it down to 40% of its size in the
        // center of the screen, then do a "hinge" animation where the top right corner
        // releases and it falls down around the top left corner, then the whole image
        // falls off the bottom of the page.
        let easeInOut = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        let easeLinear = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                completion()
            }

            // Move the anchor point to the top left, so that the rotation effect looks like
            // it's falling down on the right side. This will move the overlay, so make sure
            // that we recenter it.
            view.layer.anchorPoint = CGPoint(x: 0, y: 0)
            view.center = CGPoint(x: view.center.x * 0.6, y: view.center.y * 0.6)

            let second = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            second.fillMode = CAMediaTimingFillMode.forwards
            second.isRemovedOnCompletion = false
            second.beginTime = 0.1
            second.duration = 3.5

            let t = Float.pi / 7
            let k = Float.pi / 9
            second.values = [0.0] +
                [2.56, -1.28, 0.64, -0.32, 0.16, -0.08, 0.04, -0.02, 0.01].map { t + $0 * k } +
                [t]
            second.keyTimes = (0...10).map { (Double($0) * 0.1) as NSNumber }
            second.timingFunctions = [CAMediaTimingFunction](repeating: easeInOut, count: 10)

            let third = CAKeyframeAnimation(keyPath: "position.y")
            third.fillMode = CAMediaTimingFillMode.forwards
            third.isRemovedOnCompletion = false
            third.beginTime = second.beginTime + second.duration
            third.duration = 1.0
            third.values = [view.frame.origin.y, view.superview!.frame.height * 2]
            third.keyTimes = [0.0, 1.0]
            third.timingFunctions = [easeLinear]

            let group = CAAnimationGroup()
            group.duration = third.beginTime + third.duration
            group.fillMode = CAMediaTimingFillMode.forwards
            group.isRemovedOnCompletion = false
            group.animations = [second, third]
            view.layer.add(group, forKey:nil)
            CATransaction.commit()
        }

        let first = CAKeyframeAnimation(keyPath: "transform.scale")
        first.fillMode = CAMediaTimingFillMode.forwards
        first.isRemovedOnCompletion = false
        first.beginTime = 0.0
        first.duration = 1.0
        first.values =   [1.0, 0.35, 0.425, 0.3875, 0.40625, 0.3969, 0.4]
        first.keyTimes = [0.0, 0.5,  0.6,   0.7,    0.8,     0.9,    1.0]
        first.timingFunctions = [easeInOut, easeInOut, easeInOut, easeInOut, easeInOut]
        view.layer.add(first, forKey: nil)
        CATransaction.commit()
    }
}
