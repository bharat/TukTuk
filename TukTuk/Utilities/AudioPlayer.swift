//
//  Audio.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/6/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import AVKit

class AudioPlayer {
    static var instance = AudioPlayer()
    private let queue = DispatchQueue(label: "AudioPlayer")

    var player: AVAudioPlayer?
    var timer: Timer?
    var old: AVAudioPlayer?

    fileprivate init() {
    }

    var isPlaying: Bool {
        return queue.sync {
            player?.isPlaying ?? false
        }
    }

    // We purposefully don't do any error handling here because this has never failed in practice
    // and there's no graceful way to handle it. If this app can't play audio, it might as well crash.
    func play(_ url: URL, whilePlaying tick: @escaping () -> () = {}, whenComplete done: @escaping () -> () = {}) {
        try! AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try! AVAudioSession.sharedInstance().setActive(true)

        queue.sync {
            old?.stop()
            old = player
            old?.setVolume(0.0, fadeDuration: 1.0)

            try! player = AVAudioPlayer(contentsOf: url)

            guard let player = player else {
                return
            }

            player.play()
            if old == nil {
                player.volume = 1.0
            } else {
                player.setVolume(1.0, fadeDuration: 1.0)
            }

            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { timer in
                if self.player?.isPlaying ?? false {
                    tick()
                } else {
                    timer.invalidate()
                    done()
                }
            })
        }
    }
    
    func stop() {
        queue.sync {
            old?.stop()
            old = nil

            player?.stop()
            player = nil

            timer?.invalidate()
            timer = nil
        }
    }
}
