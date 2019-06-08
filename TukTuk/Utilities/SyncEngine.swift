//
//  SyncEngine.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/6/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation

class SyncEngine {
    private let queue = OperationQueue()

    var cloudSongs = CloudSongDict()
    var cloudMovies = CloudMovieDict()
    var songTitlesToDelete: [String] = []
    var songTitlesToDownload: [String] = []
    var movieTitlesToDelete: [String] = []
    var movieTitlesToDownload: [String] = []
    var totalOperationCount: Int = 0
    var cancelInProgress: Bool = false
    var notify: ()->() = {}

    var inProgress: Bool {
        return queue.operationCount > 0
    }
    
    var progress: Float {
        return Float(totalOperationCount - queue.operationCount) / Float(totalOperationCount)
    }

    init(concurrency: Int = 6) {
        queue.maxConcurrentOperationCount = concurrency
    }

    func calculate() {
        guard !inProgress else { return }

        let cloudSongTitles = Set(cloudSongs.keys)
        let localSongTitles = Set(LocalStorage.instance.songs.keys)
        songTitlesToDelete = Array(localSongTitles.subtracting(cloudSongTitles))
        songTitlesToDownload = Array(cloudSongTitles.subtracting(localSongTitles))

        let cloudMovieTitles = Set(cloudMovies.keys)
        let localMovieTitles = Set(LocalStorage.instance.movies.keys)
        movieTitlesToDelete = Array(localMovieTitles.subtracting(cloudMovieTitles))
        movieTitlesToDownload = Array(cloudMovieTitles.subtracting(localMovieTitles))

        totalOperationCount = songTitlesToDelete.count + songTitlesToDownload.count + movieTitlesToDelete.count + movieTitlesToDownload.count
    }

    func run() {
        guard !inProgress else { return }

        var operations: [()->()] = []
        operations += songTitlesToDelete.map { title in
            let song = LocalStorage.instance.songs[title]!
            return self.wrap {
                    LocalStorage.instance.delete(song)
            }
        }
        operations += songTitlesToDownload.map { title in
            let song = cloudSongs[title]!
            return self.wrap {
                if let tmp = GoogleDrive.instance.download(song) {
                    LocalStorage.instance.add(tmp)
                }
            }
        }
        operations += movieTitlesToDelete.map { title in
            let movie = LocalStorage.instance.movies[title]!
            return self.wrap {
                LocalStorage.instance.delete(movie)
            }
        }
        operations += movieTitlesToDownload.map { title in
            let movie = cloudMovies[title]!
            return self.wrap {
                if let tmp = GoogleDrive.instance.download(movie) {
                    LocalStorage.instance.add(tmp)
                }
            }
        }

        operations.shuffled().forEach { op in
            queue.addOperation {
                op()
            }
        }
    }

    func cancel() {
        cancelInProgress = true
    }

    fileprivate func wrap(block: @escaping ()->()) -> ()->() {
        return {
            if !self.cancelInProgress {
                block()
            }
            self.notify()

            if self.queue.operationCount == 1 {
                self.cancelInProgress = false
            }
        }
    }
}
