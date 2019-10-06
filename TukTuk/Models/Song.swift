//
//  Song.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/12/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

struct Song: Manageable {
    var title: String
    var image: LocalFile?
    var audio: LocalFile?
    var cloudImage: CloudFile?
    var cloudAudio: CloudFile?

    var artist: String {
        "ARTIST"
    }

    var duration: Int {
        100
    }

    var hasLocal: Bool {
        return image != nil && image!.exists && audio != nil && audio!.exists
    }

    var hasCloud: Bool {
        return cloudImage != nil && cloudAudio != nil
    }

    var uiImage: UIImage? {
        guard let image = image else { return nil }
        return UIImage(contentsOfFile: image.url.path)
    }

    var syncAction: SyncAction {
        if let cloudImage = cloudImage, let cloudAudio = cloudAudio {
            if let image = image, let audio = audio {
                if image.exists && cloudImage.size == image.size && audio.exists && cloudAudio.size == audio.size {
                    return .None
                } else {
                    return .Download
                }
            } else {
                return .Download
            }
        } else {
            return .Delete
        }
    }

    mutating func deleteLocal() {
        audio?.delete()
        audio = nil
        image?.delete()
        image = nil
    }

    func play(whilePlaying: @escaping ()->()={}, whenComplete: @escaping ()->()={}) {
        guard let audio = audio else { return }
        SongPlayer.instance.play(audio.url, whilePlaying: whilePlaying, whenComplete: whenComplete)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: 0,
        ]
    }
}

extension Song {
    init(title: String) {
        self.title = title
    }
}
