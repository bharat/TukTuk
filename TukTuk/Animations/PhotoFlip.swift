//
//  CurlUp.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/24/19.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit

class PhotoFlip: Animation {
    var title: String = "Photo Flip"

    required init() {
    }

    struct tx {
        var from: UIView
        var to: UIView
        var duration: TimeInterval
        var delay: TimeInterval
    }

    func animate(view: UIView, completion: @escaping ()->()) {
        Sound.Player_Welcome.play()

        let views: [UIView] = Array(1...9).map { i in
            let v = UIImageView(frame: view.frame)
            v.contentMode = .scaleAspectFill
            v.clipsToBounds = true
            v.image = UIImage(named: "CurlUp_\(i)")
            v.layer.borderWidth = 8
            v.layer.borderColor = UIColor.black.cgColor
            v.layer.cornerRadius = 0
            v.isUserInteractionEnabled = false
            return v
        }.shuffled()

        let txs = [
            tx(from: view,     to: views[0], duration: 0.50, delay: 0.50),
            tx(from: views[0], to: views[1], duration: 0.50, delay: 0.50),
            tx(from: views[1], to: views[2], duration: 0.40, delay: 0.00),
            tx(from: views[2], to: views[3], duration: 0.35, delay: 0.00),
            tx(from: views[3], to: views[4], duration: 0.30, delay: 0.00),
            tx(from: views[4], to: views[5], duration: 0.25, delay: 0.00),
            tx(from: views[5], to: views[6], duration: 0.20, delay: 0.00),
            tx(from: views[6], to: views[7], duration: 0.15, delay: 0.00),
            tx(from: views[7], to: views[8], duration: 0.50, delay: 0.50),
            tx(from: views[8], to: view,     duration: 0.15, delay: 0.00),
        ]
        transition(txs)

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            completion()
        }
    }

    func transition(_ txs: [tx]) {
        guard let tx = txs.first else { return }

        UIView.transition(from: tx.from, to: tx.to, duration: tx.duration, options: [.transitionCurlUp, .curveEaseOut]) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + tx.delay) {
                self.transition(Array(txs.dropFirst()))
            }
        }
    }
}
