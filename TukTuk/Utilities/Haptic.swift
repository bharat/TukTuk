//
//  Haptic.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 11/15/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation
import CoreHaptics

class Haptic {
    private var engine: CHHapticEngine
    private var player: CHHapticAdvancedPatternPlayer
    private var looping = true

    init(pattern: CHHapticPattern) {
        engine = try! CHHapticEngine()

        engine.stoppedHandler = { reason in
          print("Stopped for reason: \(reason.rawValue)")
        }

        do {
            try engine.start()
            player = try! engine.makeAdvancedPlayer(with: pattern)
        } catch let error {
          fatalError("Unable to start: \(error)")
        }

        player.completionHandler = { error in
            if self.looping {
                self.start()
            }
        }
    }

    func start() {
        try! player.start(atTime: 0.0)
    }

    func stop() {
        looping = false
        try! player.stop(atTime: 0)
    }
}
