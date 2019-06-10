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

    var cloudSongs: Song.CloudDict?
    var cloudMovies: Movie.CloudDict?
    var totalOps: Int = 0
    var cancelInProgress: Bool = false
    var notify: ()->() = {}

    var inProgress: Bool {
        return queue.operationCount > 0
    }
    
    var progress: Float {
        return Float(totalOps - queue.operationCount) / Float(totalOps)
    }

    var syncRequired: Bool {
        return Set(cloudSongs?.keys ?? Song.CloudDict().keys) != Set(LocalStorage.instance.songs?.keys ?? Song.LocalDict().keys)
            || Set(cloudMovies?.keys ?? Movie.CloudDict().keys) != Set(LocalStorage.instance.movies?.keys ?? Movie.LocalDict().keys)
    }

    init(concurrency: Int = 6) {
        queue.maxConcurrentOperationCount = concurrency
    }

    func cancel() {
        cancelInProgress = true
    }

    func run(complete: @escaping () -> ()) {
        guard !inProgress else { return }

        queueSongs()
        queueMovies()
        queue.addOperation {
            complete()
        }
        totalOps = queue.operationCount
    }

    fileprivate func queueSongs() {
        guard let cloudSongs = cloudSongs, let localSongs = LocalStorage.instance.songs else { return }
        let cloud = Set(cloudSongs.keys)
        let local = Set(localSongs.keys)

        local.subtracting(cloud).forEach { title in
            enqueue {
                localSongs[title]!.delete()
            }
        }

        cloud.subtracting(local).forEach { title in
            enqueue {
                cloudSongs[title]!.download()
            }
        }
    }

    fileprivate func queueMovies() {
        guard let cloudMovies = cloudMovies, let localMovies = LocalStorage.instance.movies else { return }
        let cloud = Set(cloudMovies.keys)
        let local = Set(localMovies.keys)

        local.subtracting(cloud).forEach { title in
            enqueue {
                localMovies[title]!.delete()
            }
        }

        cloud.subtracting(local).forEach { title in
            enqueue {
                cloudMovies[title]!.download()
            }
        }
    }

    fileprivate func enqueue(block: @escaping ()->()) {
        queue.addOperation {
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
