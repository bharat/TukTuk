//
//  MusicVideoPlayer.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/16/20.
//  Copyright © 2020 Menalto. All rights reserved.
//

import Foundation
import AVKit

class MusicVideoPlayer {
    var player: AVPlayer?
    var timer: Timer?
    var whenComplete: ()->() = {}
    private let queue = DispatchQueue(label: "MusicVideoPlayer")
    
    func play(_ video: URL, on layer: AVPlayerLayer, whilePlaying: @escaping ()->(), whenComplete: @escaping ()->()) {
        queue.sync {
            player = AVPlayer(url: video)
            layer.player = player
            player?.play()
            
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {
                timer in
                whilePlaying()
            }

            NotificationCenter.default.addObserver(self, selector: #selector(stop), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
            self.whenComplete = whenComplete
        }
    }
    
    func isPlaying(_ video: URL?) -> Bool {
        queue.sync {
            guard let video = video, let activeVideo = player?.currentURL else {
                return false
            }
            return video == activeVideo
        }
    }
    
    func attach(to layer: AVPlayerLayer) {
        queue.sync {
            layer.player = player
        }
    }
    
    @objc func stop() {
        queue.sync {
            timer?.invalidate()
            timer = nil
            player?.pause()
            whenComplete()
        }
    }
}
