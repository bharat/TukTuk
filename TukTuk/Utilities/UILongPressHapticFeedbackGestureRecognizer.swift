//
//  UILongPressHapticFeedbackGestureRecognizer.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/18/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation
import UIKit

class UILongPressHapticFeedbackGestureRecognizer: UILongPressGestureRecognizer {
    let impact = UIImpactFeedbackGenerator()
    var timer: Timer? = nil

    func startTimer(interval: TimeInterval) {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { timer in
            self.impact.impactOccurred()
            self.startTimer(interval: max(interval - 0.06, 0.1))
        }
    }

    func stopTimer() {
        timer?.invalidate()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        self.impact.impactOccurred()
        super.touchesBegan(touches, with: event)
        startTimer(interval: 0.7)
    }

    override func reset() {
        super.reset()
        stopTimer()
    }
}
