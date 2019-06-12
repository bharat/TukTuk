//
//  Movies.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/10/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation

class Movies {
    static let instance = Movies()
    let queue = DispatchQueue(label: "MoviesWorker")
    let base: URL
    let fm = FileManager.default
    var local = Set<Local>()
    var cloud = Set<Cloud>()

    fileprivate init() {
        base = fm.documentsSubdirectoryUrl("Movies")

        try! FileManager.default.contentsOfDirectory(atPath: base.path).forEach { fileName in
            let title = NSString(string: fileName).deletingPathExtension
            local.insert(Local(title: title, base: base))
        }
    }

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

    func load(from provider: CloudProvider) {
        let files = provider.list(folder: provider.moviesFolder)
        files?.forEach { file in
            let name = NSString(string: file.name).deletingPathExtension
            queue.sync {
                let _ = self.cloud.insert(Cloud(title: name, id: file.id, size: UInt64(truncating: file.size)))
            }
        }
    }

    func download(_ cloud: Cloud, from provider: CloudProvider) {
        guard let data = provider.get(file: cloud.id) else { return }

        let movie = Local(title: cloud.title, base: base)
        FileManager.default.createFile(atPath: movie.video.path, contents: data, attributes: nil)
        FileManager.default.excludeFromBackup(movie.video)
        queue.sync {
            let _ = local.insert(movie)
        }
    }

    func delete(_ movie: Local) {
        queue.sync {
            let _ = local.remove(movie)
        }
        try! FileManager.default.removeItem(atPath: movie.video.path)
    }

    func deleteAll() {
        queue.sync {
            local.forEach { movie in
                let _ = local.remove(movie)
                try! FileManager.default.removeItem(atPath: movie.video.path)
            }
        }
    }
}

extension Movies {
    struct Local: VideoPlayable, Titled, Hashable {
        var title: String
        var base: URL

        var video: URL {
            return base.appendingPathComponent("\(title).mp4")
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(title)
            hasher.combine(FileManager.default.fileSize(video))
        }
    }

    struct Cloud: Hashable {
        var title: String
        var id: String
        var size: UInt64

        func hash(into hasher: inout Hasher) {
            hasher.combine(title)
            hasher.combine(size)
        }
    }

}
