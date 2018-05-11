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
    var audioPlayer: AVAudioPlayer?

    private init() {
    }

    var isPlaying: Bool {
        return audioPlayer?.isPlaying ?? false
    }

    func play(_ url: URL, withCrossFade: Bool = false) {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)

            let old = audioPlayer
            audioPlayer = try AVAudioPlayer(contentsOf: url)

            if let new = audioPlayer {
                new.play()

                if let old = old {
                    if withCrossFade {
                        new.volume = 0
                        crossFade(from: old, to: new)
                    } else {
                        old.volume = 0
                    }
                }
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }

    func crossFade(from old: AVAudioPlayer, to new: AVAudioPlayer) {
        if new.volume < 1.0 {
            old.volume -= 0.1
            new.volume += 0.1

            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
                self.crossFade(from: old, to: new)
            }
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}
