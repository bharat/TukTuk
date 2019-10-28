//
//  AdminTabBarController.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/8/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation
import UIKit
import SwiftyGif
import CoreHaptics

class AdminTabBarController: UITabBarController {
    override func viewDidLoad() {
        if Manager.songs.localEmpty {
            // Jump to the Sync tab
            selectedIndex = 1
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + [30, 40, 50].randomElement()!) {
            self.showBunny()
        }
    }
    
    func showBunny() {
        do {
            let bunnyImage = try UIImage(gifName: "BunnyRun.gif")
            let bunnyImageView = UIImageView(gifImage: bunnyImage, loopCount: -1)
            
            let width = CGFloat(370 / 4)
            let height = CGFloat(272 / 4)
            bunnyImageView.frame = CGRect(x: -width, y: view.frame.height - height, width: width, height: height)
            view.addSubview(bunnyImageView)

            UIView.animate(withDuration: 3.0, animations: {
                bunnyImageView.layer.position.x = self.view.frame.width
            }, completion: { _ in
                bunnyImageView.removeFromSuperview()
            })
        } catch {
            print(error)
        }
        
        if #available(iOS 13.0, *) {
            guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
            var engine: CHHapticEngine?
            
            do {
                engine = try CHHapticEngine()
                try engine?.start()
            } catch {
                print("There was an error creating the engine: \(error.localizedDescription)")
            }

            // create a dull, strong haptic
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0)
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1)

            // create a curve that fades from 1 to 0 over one second
            let start = CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 1)
            let end = CHHapticParameterCurve.ControlPoint(relativeTime: 1, value: 0)

            // use that curve to control the haptic strength
            let parameter = CHHapticParameterCurve(parameterID: .hapticIntensityControl, controlPoints: [start, end], relativeTime: 0)

            // create a continuous haptic event starting immediately and lasting one second
            let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [sharpness, intensity], relativeTime: 0, duration: 1)

            // now attempt to play the haptic, with our fading parameter
            do {
                let pattern = try CHHapticPattern(events: [event], parameterCurves: [parameter])

                let player = try engine?.makePlayer(with: pattern)
                try player?.start(atTime: 0)
            } catch {
                // add your own meaningful error handling here!
                print(error.localizedDescription)
            }
        }
    }
}
