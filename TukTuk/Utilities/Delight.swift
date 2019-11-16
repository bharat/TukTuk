//
//  Delight.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 10/27/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation
import UIKit
import SwiftyGif
import CoreHaptics


class Delight {
    func showBunny(on parent: UIView) {
        do {
            let bunnyImage = try UIImage(gifName: "BunnyRun.gif")
            let bunnyImageView = UIImageView(gifImage: bunnyImage, loopCount: -1)

            let width = CGFloat(370 / 4)
            let height = CGFloat(272 / 4)
            bunnyImageView.frame = CGRect(x: -width, y: parent.frame.height - height, width: width, height: height)
            parent.addSubview(bunnyImageView)

            let haptic = Haptic(pattern: bunnyFootfalls())
            haptic.start()
            UIView.animate(withDuration: 3.0, animations: {
                bunnyImageView.layer.position.x = parent.frame.width
            }, completion: { _ in
                bunnyImageView.removeFromSuperview()
                haptic.stop()
            })
        } catch {
            print(error)
        }
    }
    
    func bunnyFootfalls() -> CHHapticPattern {
        let intenseFull = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let intenseHalf = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5)
        let sharpnessFull = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        let sharpnessHalf = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        let events = [
            CHHapticEvent(eventType: .hapticTransient, parameters: [intenseFull, sharpnessFull], relativeTime: 0.0, duration: 0.1),
            CHHapticEvent(eventType: .hapticTransient, parameters: [intenseFull, sharpnessHalf], relativeTime: 0.1, duration: 0.1),
            CHHapticEvent(eventType: .hapticTransient, parameters: [intenseHalf, sharpnessHalf], relativeTime: 0.2, duration: 0.1),
            CHHapticEvent(eventType: .hapticTransient, parameters: [intenseHalf, sharpnessHalf], relativeTime: 0.3, duration: 0.1),
        ]
        return try! CHHapticPattern(events: events, parameters: [])
    }
}
