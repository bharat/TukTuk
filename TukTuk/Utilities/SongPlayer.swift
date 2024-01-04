//
//  SongPlayer.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/16/20.
//  Copyright © 2020 Menalto. All rights reserved.
//

import Foundation

class SongPlayer {
    let musicVideoPlayer = MusicVideoPlayer()
    private let queue = DispatchQueue(label: "SongPlayer")
    private var activeSong: Song?

    func stop() {
        queue.sync {
            if let activeSong = activeSong {
                Stats().stop(song: activeSong)
            }

            AudioPlayer.instance.stop()
            musicVideoPlayer.stop()
        }
    }
    
    func play(_ song: Song, on cell: SongCell, whilePlaying: @escaping ()->(), whenComplete: @escaping ()->()) {
        queue.sync {
            musicVideoPlayer.stop()
            if song.hasMusicVideo {
                print("Playing music video: \(song.title)")
                AudioPlayer.instance.stop()
                musicVideoPlayer.play(song.video!.url, on: cell.videoLayer, whilePlaying: whilePlaying, whenComplete: whenComplete)
            } else {
                print("Playing song: \(song.title)")
                song.play(whilePlaying: whilePlaying, whenComplete: whenComplete)
            }
            activeSong = song
        }
    }
    
    func maybeReattachVideo(_ song: Song, to cell: SongCell) {
        queue.sync {
            if let video = song.video?.url {
                if musicVideoPlayer.isPlaying(video) {
                    musicVideoPlayer.attach(to: cell.videoLayer)
                }
            }
        }
    }
}
