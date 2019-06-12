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
    var data = [String:Movie]()

    var inSync: Bool {
        return queue.sync {
            data.values.filter { $0.syncAction != .None }.count == 0
        }
    }

    var download: [Movie] {
        return queue.sync {
            data.values.filter { $0.syncAction == .Download }
        }
    }

    var delete: [Movie] {
        return queue.sync {
            data.values.filter { $0.syncAction == .Delete }
        }
    }

    var local: [Movie] {
        return queue.sync {
            data.values.filter { $0.video != nil }
        }
    }

    var cloud: [Movie] {
        return queue.sync {
            data.values.filter { $0.cloudVideo != nil }
        }
    }

    var localEmpty: Bool {
        return local.count == 0
    }

    fileprivate init() {
        base = fm.documentsSubdirectoryUrl("Movies")

        let names = try! FileManager.default.contentsOfDirectory(atPath: base.path).map { fileName in
            NSString(string: fileName).deletingPathExtension
        }
        names.forEach { name in
            let video = LocalFile(url: base.appendingPathComponent("\(name).mp4"))
            let movie = Movie(title: name, video: video, cloudVideo: nil)
            queue.sync {
                data[movie.title] = movie
            }
        }
    }

    func load(from provider: CloudProvider) {
        let files = provider.list(folder: provider.moviesFolder)
        files?.forEach { file in
            let title = NSString(string: file.name).deletingPathExtension
            var movie = queue.sync {
                data[title] ?? Movie(title: title)
            }
            movie.cloudVideo = file
            queue.sync {
                data[movie.title] = movie
            }
        }
    }

    func download(_ movie: Movie, from provider: CloudProvider) {
        guard let cloud = movie.cloudVideo else { return }
        guard let videoData = provider.get(file: cloud.id) else { return }

        let video = LocalFile(url: base.appendingPathComponent("\(movie.title).mp4"))
        fm.createNonBackupFile(at: video.url, contents: videoData)

        queue.sync {
            var movie = movie
            movie.video = video
            data[movie.title] = movie
        }
    }

    func delete(_ movie: Movie) {
        queue.sync {
            let _ = data.removeValue(forKey: movie.title)
        }
        if let path = movie.video?.url.path {
            try! fm.removeItem(atPath: path)
        }
    }

    func deleteAllLocal() {
        local.forEach { movie in
            delete(movie)
        }
    }
}

struct Movie: Titled, Hashable {
    var title: String
    var video: LocalFile?
    var cloudVideo: CloudFile? = nil

    var syncAction: SyncAction {
        if let cloudVideo = cloudVideo {
            if let video = video {
                if cloudVideo.size == video.size {
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

extension Movie {
    init(title: String) {
        self.title = title
    }
}
