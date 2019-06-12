//
//  Songs.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 7/10/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit

class Songs {
    static let instance = Songs()
    let queue = DispatchQueue(label: "SongsWorker")
    let base: URL
    let fm = FileManager.default
    var data = [String:Song]()

    var inSync: Bool {
        return queue.sync {
            data.values.filter { $0.syncAction != .None }.count == 0
        }
    }

    var download: [Song] {
        return queue.sync {
            data.values.filter { $0.syncAction == .Download }
        }
    }

    var delete: [Song] {
        return queue.sync {
            data.values.filter { $0.syncAction == .Delete }
        }
    }

    var local: [Song] {
        return queue.sync {
            data.values.filter { $0.image != nil && $0.audio != nil }
        }
    }

    var cloud: [Song] {
        return queue.sync {
            data.values.filter { $0.cloudAudio != nil && $0.cloudImage != nil }
        }
    }

    var localEmpty: Bool {
        return local.count == 0
    }

    fileprivate init() {
        base = fm.documentsSubdirectoryUrl("Songs")

        let names = Set(try! fm.contentsOfDirectory(atPath: base.path).map { fileName in
            NSString(string: fileName).deletingPathExtension
        })
        names.forEach { name in
            let image = LocalFile(url: base.appendingPathComponent("\(name).png"))
            let audio = LocalFile(url: base.appendingPathComponent("\(name).mp3"))
            let song = Song(title: name, image: image, audio: audio, cloudImage: nil, cloudAudio: nil)
            queue.sync {
                data[song.title] = song
            }
        }
    }

    func load(from provider: CloudProvider) {
        let files = provider.list(folder: provider.songsFolder)

        files?.forEach { file in
            let title = NSString(string: file.name).deletingPathExtension
            let ext = NSString(string: file.name).pathExtension
            var song = queue.sync {
                data[title] ?? Song(title: title)
            }
            if ext == "mp3" {
                song.cloudAudio = file
            } else {
                song.cloudImage = file
            }
            queue.sync {
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

struct LocalFile: Hashable {
    var url: URL

    var size: UInt64 {
        return FileManager.default.fileSize(url)
    }
}

enum SyncAction: Hashable {
    case Download
    case Delete
    case None
}

struct Song: Titled, Hashable {
    var title: String
    var image: LocalFile?
    var audio: LocalFile?
    var cloudImage: CloudFile?
    var cloudAudio: CloudFile?

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
