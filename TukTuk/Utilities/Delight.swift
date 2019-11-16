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

class BunnyDelight {
    var haptic: HapticPlayer?
    var imageView: UIImageView
    var parent: UIView!
    
    init() {
//        let bunnyImage = UIImage(named: "Avenger_Thor")
//        imageView = UIImageView(image: bunnyImage)
        let bunnyImage = try! UIImage(gifName: "Delight_BunnyRun.gif")
        imageView = UIImageView(gifImage: bunnyImage, loopCount: 10)
        haptic = try? HapticPlayer(pattern: footfallPattern())
    }
    
    func show(on parent: UIView) {
        self.parent = parent
        
        let width = CGFloat(370 / 4)
        let height = CGFloat(272 / 4)
//        imageView.frame = CGRect(x: -width, y: parent.frame.height - height, width: width, height: height)
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:))))
        parent.addSubview(imageView)
        
        imageView.frame = CGRect(x: 40, y: parent.frame.height - height, width: width, height: height)

//        haptic?.start()
//        UIView.animate(withDuration: 10.0, animations: {
//            self.imageView.layer.position.x = parent.frame.width
//        }, completion: { _ in
////            self.imageView.removeFromSuperview()
//            self.haptic?.stop()
//        })
    }

    @objc func handleTap(sender: UITapGestureRecognizer) {
        print("tap!")
//        haptic?.stop()
//        imageView.stopAnimating()
//
//        let heartImage = UIImage(named: "Delight_Heart")
//        let heartImageView = UIImageView(image: heartImage)
//        heartImageView.frame = imageView.frame
//        parent.addSubview(heartImageView)
//
//        UIView.animate(withDuration: 5.0, animations: {
//            heartImageView.layer.position.y = self.parent.frame.height
//        }, completion: { _ in
//            heartImageView.removeFromSuperview()
//        })
    }
    
    func footfallPattern() throws -> CHHapticPattern {
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
        return try CHHapticPattern(events: events, parameters: [])
    }
}
