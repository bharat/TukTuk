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
    var image: LocalFile?
    var audio: LocalFile?
    var video: LocalFile?
    var cloudImage: CloudFile?
    var cloudAudio: CloudFile?
    var cloudVideo: CloudFile?
    
//    var video: URL? {
//        if displayTitle == "Take On Me" {
//            return Media.Player.video("TakeOnMe")
//        }
//        return nil
//    }

    var duration: Int = 0

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
        // Image and audio are mandatory
        guard let cloudImage = cloudImage, let cloudAudio = cloudAudio else {
            return .Delete
        }
        
        guard let image = image, let audio = audio else {
            return .Download
        }
        
        if !image.exists || !audio.exists {
            return .Download
        }
        
        if cloudImage.size != image.size || cloudAudio.size != audio.size {
            return .Download
        }

        // Cloud video is optional- so if there is none then we're up to date
        guard let cloudVideo = cloudVideo else {
            return .None
        }

        guard let video = video else {
            return .Download
        }
        
        if !video.exists {
            return .Download
        }
        
        if cloudVideo.size != video.size {
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
