//
//  Video.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/6/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import AVKit

class VideoViewController: AVPlayerViewController {
    var movie: URL?

    override func viewDidLoad() {
        showsPlaybackControls = false

        if let movie = movie {
            let asset = AVAsset(url: movie)
            let playerItem = AVPlayerItem(asset: asset)
            player = AVPlayer(playerItem: playerItem)
            player?.allowsExternalPlayback = false
            player?.play()

            // DEBUG - seek to almost the end to test termination
            // player?.seek(to: CMTime(seconds: asset.duration.seconds - 5.0, preferredTimescale: asset.duration.timescale))

            NotificationCenter.default.addObserver(self, selector: #selector(done), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        }
    }

    func stop() {
        player?.pause()
    }

    func start() {
        player?.play()
    }

    @objc func done() {
        self.dismiss(animated: true)
    }
}
