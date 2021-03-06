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
    static var instance = VideoPlayer()

    var vc: AVPlayerViewController
    var completion = {}

    fileprivate init() {
        vc = AVPlayerViewController()
        vc.showsPlaybackControls = false
        vc.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pauseOrResume)))
    }

    func play(_ url: URL, from sender: UIViewController, completion: @escaping () -> () = {}) {
        self.completion = completion

        vc.player = AVPlayer(url: url)
        vc.modalPresentationStyle = .fullScreen
        vc.player?.play()

        sender.show(vc, sender: sender)

        NotificationCenter.default.addObserver(self, selector: #selector(hide), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: vc.player?.currentItem)
    }

    var isStopped: Bool {
        return vc.player?.timeControlStatus != .playing
    }

    @objc func pauseOrResume() {
        if isStopped {
            vc.player?.play()
        } else {
            vc.player?.pause()
        }
    }

    @objc func hide() {
        vc.dismiss(animated: true, completion: completion)
    }
}
