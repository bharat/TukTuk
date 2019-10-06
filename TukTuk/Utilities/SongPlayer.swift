//
//  Audio.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/6/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import AVKit
import MediaPlayer

// We purposefully don't do any error handling here because this has never failed in practice
// and there's no graceful way to handle it. If this app can't play audio, it might as well crash.
class SongPlayer {
    static var instance = SongPlayer()
    private let queue = DispatchQueue(label: "SongPlayer")

    var player: AVAudioPlayer?
    var timer: Timer?

    fileprivate init() {
        try! AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try! AVAudioSession.sharedInstance().setActive(true)

        UIApplication.shared.beginReceivingRemoteControlEvents();
        MPRemoteCommandCenter.shared().playCommand.addTarget { event in
            self.player?.play()
            return .success
        }
        MPRemoteCommandCenter.shared().pauseCommand.addTarget {event in
            self.player?.pause()
            return .success
        }
        MPRemoteCommandCenter.shared().nextTrackCommand.addTarget {event in
            return .success
        }
        MPRemoteCommandCenter.shared().previousTrackCommand.addTarget {event in
            return .success
        }
    }

    var isPlaying: Bool {
        return queue.sync {
            player?.isPlaying ?? false
        }
    }

    func play(_ url: URL, whilePlaying tick: @escaping ()->()={}, whenComplete done: @escaping ()->()={}) {

        queue.sync {
            let new = try! AVAudioPlayer(contentsOf: url)
            new.play()

            if player == nil {
                new.volume = 1.0
            } else {
                player?.setVolume(0.0, fadeDuration: 1.0)
                new.setVolume(1.0, fadeDuration: 1.0)
            }
            player = new

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
            player?.stop()
            player = nil

            timer?.invalidate()
            timer = nil
        }
    }
}
