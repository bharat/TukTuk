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

extension Media {
    static let BunnyDelight = Media("BunnyDelight")
}

class BunnyDelight {
    var parent: UIView!

    func show(on parent: UIView) {
        self.parent = parent
        
        let bunnyImage = try! UIImage(gifName: "Delight_BunnyRun.gif")
        let imageView = UIImageView(gifImage: bunnyImage, loopCount: -1)
        let haptic = try? HapticPlayer(pattern: footfallPattern())
        
        let width = CGFloat(370 / 4)
        let height = CGFloat(272 / 4)
        
        // Tap gestures won't work on the animated image because of the way that presentation layers work.
        // Insead, create an outer view to trap taps and then check to see if they're inside the animating image.
        let outerView = UIView()
        outerView.frame = CGRect(x: 0, y: parent.frame.height - height, width: parent.frame.width, height: height)
        outerView.isUserInteractionEnabled = true
        outerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:))))
        parent.addSubview(outerView)

        imageView.isUserInteractionEnabled = false
        imageView.frame = CGRect(x: -width, y: 0, width: width, height: height)
        outerView.addSubview(imageView)

        haptic?.start()
        UIView.animate(withDuration: 5.0, delay: 0.0, options: [.curveLinear], animations: {
            imageView.layer.position.x = parent.frame.width
        }, completion: { _ in
            outerView.removeFromSuperview()
            haptic?.stop()
        })
    }

    @objc func handleTap(sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: sender.view!)
        let bunnyView = sender.view!.subviews[0]
        let animatingLayerPosition = bunnyView.layer.presentation()!.position
        let bunnyFrame = CGRect(origin: animatingLayerPosition, size: bunnyView.frame.size)
        
        if bunnyFrame.contains(tapLocation) {
            let heartImage = UIImage(named: "Delight_Heart")
            let heartImageView = UIImageView(image: heartImage)

            let size = CGFloat(Array(stride(from: 50, through: 100, by: 10)).randomElement()!)
            heartImageView.frame = CGRect(x: bunnyFrame.origin.x, y: parent.frame.height - bunnyFrame.size.height, width: size, height: size)
            parent.addSubview(heartImageView)

            Sound.BunnyDelight_Coin.play(volume: 0.1)
            UIView.animate(withDuration: 2.0, delay: 0.0, options: [.curveEaseIn], animations: {
                heartImageView.layer.position.y = 0
                let angle = [-CGFloat.pi / 2, .pi / 2].randomElement()!
                heartImageView.transform = CGAffineTransform(rotationAngle: angle)
            }, completion: { _ in
                heartImageView.removeFromSuperview()
            })
        }
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
