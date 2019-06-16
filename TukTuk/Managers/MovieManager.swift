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

    func loadCloud(from provider: CloudProvider, notify: @escaping () -> ()) {
        provider.list(folder: provider.moviesFolder) { files in
            self.queue.sync {
                files.forEach { file in
                    var movie = self.data[file.title] ?? Movie(title: file.title)
                    movie.cloudVideo = file
                    self.data[movie.title] = movie
                }
            }
            notify()
        }
    }

    func download(_ movie: Movie, from provider: CloudProvider, notify: @escaping () -> ()) -> Canceler? {
        guard movie.hasCloud else { return nil }

        return provider.get(file: movie.cloudVideo!.id) { cloudData in
            if let cloudData = cloudData {
                let local = LocalFile(url: self.base.appendingPathComponent("\(movie.title).mp4"))
                self.fm.createNonBackupFile(at: local.url, contents: cloudData)

                self.queue.sync {
                    var movie = self.data[movie.title] ?? Movie(title: movie.title)
                    movie.video = local
                    self.data[movie.title] = movie
                }
            }
            notify()
        }
    }

    func deleteLocal(_ movie: Movie) {
        queue.sync {
            if var movie = data.removeValue(forKey: movie.title) {
                if movie.hasCloud {
                    movie.video = nil
                    data[movie.title] = movie
                }
            }
        }
        if let path = movie.video?.url.path {
            try! fm.removeItem(atPath: path)
        }
    }

    func deleteAllLocal() {
        data.values.forEach { movie in
            deleteLocal(movie)
        }
    }
}
