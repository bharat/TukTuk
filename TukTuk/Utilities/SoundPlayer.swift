//
//  SoundPlayer.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/6/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import AVKit
import MediaPlayer

class SoundPlayer: NSObject, AVAudioPlayerDelegate {
    static var instance = SoundPlayer()
    private let queue = DispatchQueue(label: "SoundPlayer")

    var player: AVAudioPlayer?
    var done: ()->() = {}

    func play(_ sound: Sound, volume: Float = 1.0, whenComplete done: @escaping ()->()={}) {
        queue.sync {
            // print("Playing sound: \(sound)")
            self.done = done

            try! player = AVAudioPlayer(contentsOf: sound.url)
            player?.setVolume(volume, fadeDuration: 0.0)
            player?.play()
            player?.delegate = self
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        done()
    }
}
