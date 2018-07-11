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
        return player?.timeControlStatus == .playing
    }

    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
    }
}
