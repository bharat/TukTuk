//
//  Video.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/7/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import AVKit

class Video {
    static var instance = Video()
    var playerVC = AVPlayerViewController()
    var player = AVPlayer()

    var isPlaying: Bool {
        return playerVC.isPlaying
    }

    private init() {
        playerVC.showsPlaybackControls = false
    }

    func play(_ url: URL, from sender: UIViewController) {
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        player.play()

        playerVC.player = player
        sender.present(playerVC, animated: true, completion: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(Video.hide), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
    }

    func stop() {
        player.pause()
    }

    @objc func hide() {
        playerVC.dismiss(animated: true, completion: nil)
    }

}
