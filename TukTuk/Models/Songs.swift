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
    var local = Set<Local>()
    var cloud = Set<Cloud>()

    var inSync: Bool {
        return queue.sync {
            local.hashValue == cloud.hashValue
        }
    }

    var localHashes: Set<Int> {
        return queue.sync {
            Set(local.map { $0.hashValue })
        }
    }

    var cloudHashes: Set<Int> {
        return queue.sync {
            Set(cloud.map { $0.hashValue })
        }
    }

    var missing: Set<Cloud> {
        let missingHashes = cloudHashes.subtracting(localHashes)
        return queue.sync {
            cloud.filter {
                missingHashes.contains($0.hashValue)
            }
        }
    }

    var extra: Set<Local> {
        let missingHashes = localHashes.subtracting(cloudHashes)
        return queue.sync {
            local.filter {
                missingHashes.contains($0.hashValue)
            }
        }
    }

    fileprivate init() {
        base = fm.documentsSubdirectoryUrl("Songs")

        let names = Set(try! fm.contentsOfDirectory(atPath: base.path).map { fileName in
            NSString(string: fileName).deletingPathExtension
            })
        names.forEach { name in
            queue.sync {
                let _ = local.insert(Local(title: name, base: base))
            }
        }
    }

    func load(from provider: CloudProvider) {
        let files = provider.list(folder: provider.songsFolder)

        var audio: [String:(String, UInt64)] = [:]
        var image: [String:(String, UInt64)] = [:]
        files?.forEach { file in
            let name = NSString(string: file.name).deletingPathExtension
            if NSString(string: file.name).pathExtension == "mp3" {
                audio[name] = (file.id, UInt64(truncating: file.size))
            } else {
                image[name] = (file.id, UInt64(truncating: file.size))
            }
        }
        Set(audio.keys).intersection(Set(image.keys)).forEach { name in
            let (audioId, audioSize) = audio[name]!
            let (imageId, imageSize) = image[name]!
            self.queue.sync {
                let _ = self.cloud.insert(Cloud(title: name, audioId: audioId, audioSize: audioSize, imageId: imageId, imageSize: imageSize))
            }
        }
    }

    func download(_ cloud: Cloud, from provider: CloudProvider) {
        let data = provider.get(files: [cloud.audioId, cloud.imageId])
        guard let imageData = data[cloud.imageId], let audioData = data[cloud.audioId]! else {
            return
        }

        let song = Local(title: cloud.title, base: base)
        FileManager.default.createFile(atPath: song.image.path, contents: imageData, attributes: nil)
        FileManager.default.createFile(atPath: song.audio.path, contents: audioData, attributes: nil)
        [song.image, song.audio].forEach { url in
            FileManager.default.excludeFromBackup(url)
        }
        queue.sync {
            let _ = local.insert(song)
        }
    }

    func delete(_ song: Local) {
        queue.sync {
            let _ = local.remove(song)
        }
        try! FileManager.default.removeItem(atPath: song.image.path)
        try! FileManager.default.removeItem(atPath: song.audio.path)
    }

    func deleteAll() {
        queue.sync {
            local.forEach { song in
                let _ = local.remove(song)
                try! FileManager.default.removeItem(atPath: song.image.path)
                try! FileManager.default.removeItem(atPath: song.audio.path)
            }
        }
    }
}

extension Songs {
    struct Local: AudioPlayable, Titled, Hashable {
        var title: String
        var base: URL

        var uiImage: UIImage {
            return UIImage(contentsOfFile: image.path)!
        }

        var image: URL {
            return base.appendingPathComponent("\(title).png")
        }

        var audio: URL {
            return base.appendingPathComponent("\(title).mp3")
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(title)
            hasher.combine(FileManager.default.fileSize(image))
            hasher.combine(FileManager.default.fileSize(audio))
        }
    }

    struct Cloud: Hashable {
        var title: String
        var audioId: String
        var audioSize: UInt64
        var imageId: String
        var imageSize: UInt64

        func hash(into hasher: inout Hasher) {
            hasher.combine(title)
            hasher.combine(imageSize)
            hasher.combine(audioSize)
        }
    }
}
