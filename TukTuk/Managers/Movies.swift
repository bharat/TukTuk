//
//  MovieManager.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/10/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation

class MovieManager: Manager<Movie> {
    static let instance = MovieManager()

    fileprivate init() {
        super.init(subdir: "Movies")
    }

    func loadLocal() {
        let names = try! fm.contentsOfDirectory(atPath: base.path).map { fileName in
            NSString(string: fileName).deletingPathExtension
        }
        names.forEach { name in
            queue.sync {
                var movie = data[name] ?? Movie(title: name)
                movie.video = LocalFile(url: base.appendingPathComponent("\(name).mp4"))
                data[movie.title] = movie
            }
        }
    }

    func loadCloud(from provider: CloudProvider) {
        let files = provider.list(folder: provider.moviesFolder)
        files?.forEach { file in
            queue.sync {
                var movie = data[file.title] ?? Movie(title: file.title)
                movie.cloudVideo = file
                data[movie.title] = movie
            }
        }
    }

    func download(_ movie: Movie, from provider: CloudProvider) {
        guard let cloudVideo = movie.cloudVideo else { return }
        guard let videoData = provider.get(file: cloudVideo.id) else { return }

        let video = LocalFile(url: base.appendingPathComponent("\(movie.title).mp4"))
        fm.createNonBackupFile(at: video.url, contents: videoData)

        queue.sync {
            var movie = data[movie.title] ?? Movie(title: movie.title)
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
        local.forEach { obj in
            delete(obj)
        }
    }
}

struct Movie: Manageable, Titled {
    var title: String
    var video: LocalFile?
    var cloudVideo: CloudFile?

    var hasLocal: Bool {
        return video != nil
    }

    var hasCloud: Bool {
        return cloudVideo != nil
    }

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
