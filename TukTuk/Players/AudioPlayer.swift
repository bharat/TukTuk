//
//  Audio.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/6/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import AVKit

protocol AudioPlayable {
    var audio: URL { get }
}

class AudioPlayer {
    static var instance = AudioPlayer()
    static var player: AVAudioPlayer?
    static var timer: Timer?

    // We purposefully don't do any error handling here because this has never failed in practice
    // and there's no graceful way to handle it. If this app can't play audio, it might as well crash.
    static func play(_ object: AudioPlayable, whilePlaying tick: @escaping () -> () = {}, whenComplete done: @escaping () -> () = {}) {
        try! AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try! AVAudioSession.sharedInstance().setActive(true)

        let old = player
        try! player = AVAudioPlayer(contentsOf: object.audio)

        guard let player = player else {
            return
        }

        player.play()
        if let old = old {
            player.volume = 0
            crossFade(from: old, to: player)
        } else {
            player.play()
            player.volume = 1.0
        }

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { timer in
            if player.isPlaying {
                tick()
            } else {
                timer.invalidate()
                done()
            }
        })
    }

    private static func crossFade(from old: AVAudioPlayer, to new: AVAudioPlayer) {
        if new.volume < 1.0 {
            old.volume -= 0.1
            new.volume += 0.1

            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
                self.crossFade(from: old, to: new)
            }
        }
    }
    
    static func stop() {
        player?.stop()
        player = nil
        
        timer?.invalidate()
        timer = nil
    }
}
