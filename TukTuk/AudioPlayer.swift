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
    static var player: AVAudioPlayer?
    static var timer: Timer?
    
    static func play(_ url: URL, tick: @escaping () -> () = {}) {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)

            let old = player
            player = try AVAudioPlayer(contentsOf: url)

            if let old = old, let new = player {
                new.play()
                new.volume = 0
                crossFade(from: old, to: new)
                
                if timer == nil {
                    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in tick()})
                }
            } else {
                player?.play()
                player?.volume = 1.0
            }
        } catch let error {
            print(error.localizedDescription)
        }
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
