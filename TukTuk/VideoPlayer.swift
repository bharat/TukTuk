//
//  VideoPlayer.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/7/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import AVKit

class VideoPlayer {
    static var playerVC = AVPlayerViewController()
    static var player = AVPlayer()

    static var isPlaying: Bool {
        return playerVC.isPlaying
    }

    static func play(_ url: URL, from sender: UIViewController) {
        VideoPlayer.playerVC.showsPlaybackControls = false

        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        VideoPlayer.player = AVPlayer(playerItem: playerItem)
        VideoPlayer.player.play()

        VideoPlayer.playerVC.player = VideoPlayer.player
        sender.present(VideoPlayer.playerVC, animated: true, completion: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(VideoPlayer.hide), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: VideoPlayer.player.currentItem)
    }

    static func stop() {
        player.pause()
    }

    @objc static func hide() {
        playerVC.dismiss(animated: true, completion: nil)
    }

}
