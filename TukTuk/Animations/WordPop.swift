//
//  WordPop.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/5/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit

class WordPop: Animation {
    var title: String = "Word Pop"

    func animate(view: UIView, completion: @escaping ()->()) {
        let cadence: [(words: String, duration: CFTimeInterval)] = [
            ("Hi,\nRemy!",                           1.0),
            ("Welcome\nto\nTukTuk!",                 1.0),
            ("You can\nlisten to some\nmusic here!", 2.0),
            ("Woohoooooo!",                          1.0)
        ]
        var labels: [UILabel] = []

        // Create and place labels. We start with a big label and scale it down so that
        // when we scale it back up again it doesn't have jagged edges.
        cadence.forEach {
            (text, _) in
            let label = UILabel()
            label.numberOfLines = text.filter { $0 == "\n" }.count + 1
            label.textAlignment = .center
            label.textColor = .white
            label.text = text
            label.font = .boldSystemFont(ofSize: 70)
            label.sizeToFit()
            label.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
            label.alpha = 0
            label.center = view.center
            view.addSubview(label)
            labels.append(label)
        }

        var anim = UIView.animateAndChain(withDuration: 0, delay: 0, options: .curveEaseOut, animations: {}, completion: nil)

        // Let the text sit for a bit, then animate it away by having it grow and change color while fading out.
        let colors: [UIColor] = [.red, .green, .blue, .yellow, .gray]
        cadence.enumerated().forEach {
            (i, tuple) in
            let label = labels[i]
            anim = anim.animate(withDuration: 0, animations: {
                label.alpha = 1.0
            })
                .animate(withDuration: 0.5, delay: tuple.duration - 0.5, options: .curveEaseIn, animations: {
                    label.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                    label.alpha = 0.2
                    label.textColor = colors[Int(arc4random_uniform(UInt32(colors.count)))]
                }, completion: {
                    (_) in
                    label.isHidden = true
                    label.removeFromSuperview()
                })
        }

        // Hack to put this at the end of the chain
        anim.animate(withDuration: 0, animations: {}) { _ in
            completion()
        }
    }
}
