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
    var displayTitle: String
    var displayArtist: String
    var image: LocalFileProtocol?
    var audio: LocalFileProtocol?
    var video: LocalFileProtocol?
    var cloudImage: CloudFileProtocol?
    var cloudAudio: CloudFileProtocol?
    var cloudVideo: CloudFileProtocol?

    var duration: Int = 0

    var hasLocal: Bool {
        return image?.exists ?? false && (audio?.exists ?? false || video?.exists ?? false)
    }

    var hasCloud: Bool {
        return cloudImage != nil && (cloudAudio != nil || cloudVideo != nil)
    }
    
    var hasMusicVideo: Bool {
        return video?.exists ?? false
    }

    var uiImage: UIImage? {
        guard let image = image else { return nil }
        return UIImage(contentsOfFile: image.url.path)
    }

    var syncAction: SyncAction {
        // A well-formed cloud song has an image and either an audio track or a video clip
        guard let cloudImage = cloudImage, cloudAudio != nil || cloudVideo != nil else {
            return .Delete
        }
                        
        if cloudImage.size != image?.size || cloudAudio?.size != audio?.size || cloudVideo?.size != video?.size {
            return .Download
        }
        
        return .None
    }

    mutating func deleteLocal() {
        audio?.delete()
        audio = nil
        image?.delete()
        image = nil
    }

    func play(whilePlaying: @escaping ()->()={}, whenComplete: @escaping ()->()={}) {
        guard let audio = audio else { return }
        AudioPlayer.instance.play(audio.url, whilePlaying: whilePlaying, whenComplete: whenComplete)

        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: displayTitle,
            MPMediaItemPropertyArtist: displayArtist,
            MPMediaItemPropertyPlaybackDuration: AudioPlayer.instance.player?.duration ?? 0,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: 0,
        ]

        if let uiImage = uiImage {
            let art = MPMediaItemArtwork(boundsSize: uiImage.size, requestHandler: { _ in return uiImage })
            MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] = art
        }
    }
}

extension Song {
    init(title: String) {
        self.title = title

        let pattern = "^(.*?)\\s+\\((.*)\\)$"

        let regex = try? NSRegularExpression(
          pattern: pattern,
          options: .caseInsensitive
        )

        if let match = regex?.firstMatch(in: title, options: [], range: NSRange(location: 0, length: title.utf16.count)), match.numberOfRanges == 3 {
            displayTitle = String(title[Range(match.range(at: 1), in: title)!])
            displayArtist = String(title[Range(match.range(at: 2), in: title)!])
        } else {
            displayTitle = title
            displayArtist = ""
        }
    }
}
