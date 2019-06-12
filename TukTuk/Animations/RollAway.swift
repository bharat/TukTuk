//
//  RollAway.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/5/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit

class RollAway: Animation {
    var title: String = "Roll Away"

    required init() {
    }

    func animate(view: UIView, completion: @escaping ()->()) {
        AudioPlayer.instance.play(Sounds.Welcome.audio)

        UIView.animateAndChain(withDuration: 3.5, delay: 0.0, options: [ .curveEaseIn ], animations: {
            // Transform into a circle in the left center
            view.layer.borderWidth = 5.0
            view.layer.frame = CGRect(x: 0, y: view.superview!.frame.height / 2 - 100, width: 200, height: 200)
            view.layer.cornerRadius = 100

            // While doing one full rotation
            view.layer.transform = CATransform3DMakeRotation(CGFloat.pi, 0, 0, 1)

            // Then spin and accelerate
        }, completion: nil)
            .animate(withDuration: 0.5, delay: 0.0, options: [ .curveLinear ], animations: {
                view.layer.transform = CATransform3DMakeRotation(CGFloat.pi * 2, 0, 0, 1)
            }, completion: nil)
            .animate(withDuration: 0.4, delay: 0.0, options: [ .curveLinear ], animations: {
                view.layer.transform = CATransform3DMakeRotation(CGFloat.pi, 0, 0, 1)
            }, completion: nil)
            .animate(withDuration: 0.3, delay: 0.0, options: [ .curveLinear ], animations: {
                view.layer.transform = CATransform3DMakeRotation(CGFloat.pi * 2, 0, 0, 1)
            }) { _ in
                // Then zoom off to the right
                CATransaction.begin()
                CATransaction.setCompletionBlock {
                    completion()
                }
                let spin = CABasicAnimation(keyPath: "transform.rotation")
                spin.fromValue = 0.0
                spin.toValue = CGFloat.pi * 2
                spin.isRemovedOnCompletion = false
                spin.repeatDuration = 0.5
                spin.duration = 0.3
                view.layer.add(spin, forKey: nil)

                let zoom = CABasicAnimation(keyPath: "position.x")
                zoom.fromValue = 100
                zoom.duration = 0.5
                zoom.toValue = view.superview!.frame.width + 100
                zoom.isRemovedOnCompletion = false
                zoom.fillMode = CAMediaTimingFillMode.forwards
                view.layer.add(zoom, forKey: nil)
                CATransaction.commit()
        }
    }
}
