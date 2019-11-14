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
    static func showBunny(on parent: UIView) {

        do {
            let bunnyImage = try UIImage(gifName: "BunnyRun.gif")
            let bunnyImageView = UIImageView(gifImage: bunnyImage, loopCount: -1)

            let width = CGFloat(370 / 4)
            let height = CGFloat(272 / 4)
            bunnyImageView.frame = CGRect(x: -width, y: parent.frame.height - height, width: width, height: height)
            parent.addSubview(bunnyImageView)

            UIView.animate(withDuration: 3.0, animations: {
                bunnyImageView.layer.position.x = parent.frame.width
            }, completion: { _ in
                bunnyImageView.removeFromSuperview()
            })
        } catch {
            print(error)
        }

        Delight.haptic2()
    }
    
    static func haptic2() {
        print("Haptic 2")
        if #available(iOS 13.0, *) {
            guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
            var engine: CHHapticEngine?
            
            do {
                engine = try CHHapticEngine()
                try engine?.start()
            } catch {
                print("There was an error creating the engine: \(error.localizedDescription)")
            }
            
            // The reset handler provides an opportunity to restart the engine.
            engine?.resetHandler = {
                
                print("Reset Handler: Restarting the engine.")
                
                do {
                    // Try restarting the engine.
                    try engine?.start()
                            
                    // Register any custom resources you had registered, using registerAudioResource.
                    // Recreate all haptic pattern players you had created, using createPlayer.

                } catch {
                    fatalError("Failed to restart the engine: \(error)")
                }
            }

            
            // The stopped handler alerts engine stoppage.
            engine?.stoppedHandler = { reason in
                print("Stop Handler: The engine stopped for reason: \(reason.rawValue)")
                switch reason {
                case .audioSessionInterrupt: print("Audio session interrupt")
                case .applicationSuspended: print("Application suspended")
                case .idleTimeout: print("Idle timeout")
                case .systemError: print("System error")
                case .notifyWhenFinished: print("finished")
                @unknown default:
                        print("Unknown error")
                }
            }

            let hapticDict = [
                CHHapticPattern.Key.pattern: [
                    [CHHapticPattern.Key.event: [CHHapticPattern.Key.eventType: CHHapticEvent.EventType.hapticTransient,
                          CHHapticPattern.Key.time: 0.001,
                          CHHapticPattern.Key.eventDuration: 1.0] // End of first event
                    ] // End of first dictionary entry in the array
                ] // End of array
            ] // End of haptic dictionary
            
            do {
                let pattern = try CHHapticPattern(dictionary: hapticDict)
                let player = try engine?.makePlayer(with: pattern)
                engine?.start(completionHandler:nil)
                print("Player start")
                try player?.start(atTime: 0)
                engine?.stop(completionHandler: nil)
            } catch {
                fatalError("Failed to play: \(error)")
            }
        }
    }
    
    static func haptic1() {
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
                print("Playing bunny haptic")
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
