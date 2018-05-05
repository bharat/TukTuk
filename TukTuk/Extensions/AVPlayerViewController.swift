//
//  AVPlayerViewControllerExtension.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/4/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import AVKit

extension AVPlayerViewController {
    var isPlaying: Bool {
        get {
            guard let player = player else { return false }
            if #available(iOS 10.0, *) {
                return player.timeControlStatus == .playing
            } else {
                // Fallback on earlier versions
                return player.rate != 0.0
            }
        }
    }

    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let player = player else { return }
        if self.isPlaying {
            player.pause()
        } else {
            player.play()
        }
    }
}
