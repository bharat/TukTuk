//
//  Songs.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 7/10/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit

class SongManager: Manager<Song> {
    static let instance = SongManager()

    fileprivate init() {
        super.init(subdir: "Songs")
    }

    func loadLocal() {
        let names = Set(try! fm.contentsOfDirectory(atPath: base.path).map { fileName in
            NSString(string: fileName).deletingPathExtension
        })
        names.forEach { name in
            let image = LocalFile(url: base.appendingPathComponent("\(name).png"))
            let audio = LocalFile(url: base.appendingPathComponent("\(name).mp3"))
            queue.sync {
                var song = data[name] ?? Song(title: name)
                song.image = image
                song.audio = audio
                data[song.title] = song
            }
        }
    }

    func loadCloud(from provider: CloudProvider) {
        let files = provider.list(folder: provider.songsFolder)

        files?.forEach { file in
            queue.sync {
                var song = data[file.title] ?? Song(title: file.title)
                if file.ext == "mp3" {
                    song.cloudAudio = file
                } else {
                    song.cloudImage = file
                }
                data[song.title] = song
            }
        }
    }

    func download(_ song: Song, from provider: CloudProvider) {
        guard let cloudAudio = song.cloudAudio, let cloudImage = song.cloudImage else { return }
        guard let imageData = provider.get(file: cloudImage.id) else { return }
        guard let audioData = provider.get(file: cloudAudio.id) else { return }

        let image = LocalFile(url: base.appendingPathComponent("\(song.title).png"))
        let audio = LocalFile(url: base.appendingPathComponent("\(song.title).mp3"))
        fm.createNonBackupFile(at: image.url, contents: imageData)
        fm.createNonBackupFile(at: audio.url, contents: audioData)

        queue.sync {
            var song = song
            song.image = image
            song.audio = audio
            data[song.title] = song
        }
    }

    func delete(_ song: Song) {
        queue.sync {
            let _ = data.removeValue(forKey: song.title)
        }
        [song.image?.url.path, song.audio?.url.path].forEach { path in
            if let path = path {
                try! fm.removeItem(atPath: path)
            }
        }
    }

    func deleteAllLocal() {
        local.forEach { song in
            delete(song)
        }
    }
}

struct Song: Manageable {
    var title: String
    var image: LocalFile?
    var audio: LocalFile?
    var cloudImage: CloudFile?
    var cloudAudio: CloudFile?

    var hasLocal: Bool {
        return image != nil && audio != nil
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
                if cloudImage.size == image.size && cloudAudio.size == audio.size {
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
}

extension Song {
    init(title: String) {
        self.title = title
    }
}
