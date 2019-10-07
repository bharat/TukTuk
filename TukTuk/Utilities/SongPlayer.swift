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
        UIApplication.shared.beginReceivingRemoteControlEvents();

        let mprcc = MPRemoteCommandCenter.shared()
        mprcc.playCommand.addTarget { event in
            guard let player = self.player else { return .noActionableNowPlayingItem }
            player.play()
            return .success
        }
        mprcc.pauseCommand.addTarget {event in
            guard let player = self.player else { return .noActionableNowPlayingItem }
            MPNowPlayingInfoCenter.default().nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
            player.pause()
            return .success
        }

        mprcc.changePlaybackPositionCommand.isEnabled = true
        mprcc.changePlaybackPositionCommand.addTarget {
            guard let player = self.player, let event = $0 as? MPChangePlaybackPositionCommandEvent else { return .noActionableNowPlayingItem }
            player.currentTime = event.positionTime
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
