//
//  AVPlayer.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/16/20.
//  Copyright © 2020 Menalto. All rights reserved.
//

import Foundation

import AVKit

extension AVPlayer {
    var currentURL: URL? {
        return (currentItem?.asset as? AVURLAsset)?.url
    }
}
