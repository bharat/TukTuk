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

    var cloudSongs = Song.CloudDict()
    var cloudMovies = Movie.CloudDict()
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
        return Set(self.cloudSongs.keys) != Set(LocalStorage.instance.songs.keys) ||
        Set(cloudMovies.keys) != Set(LocalStorage.instance.movies.keys)
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
        let cloud = Set(self.cloudSongs.keys)
        let local = Set(LocalStorage.instance.songs.keys)

        local.subtracting(cloud).forEach { title in
            enqueue {
                LocalStorage.instance.songs[title]!.delete()
            }
        }

        cloud.subtracting(local).forEach { title in
            enqueue {
                self.cloudSongs[title]!.download()
            }
        }
    }

    fileprivate func queueMovies() {
        let cloud = Set(cloudMovies.keys)
        let local = Set(LocalStorage.instance.movies.keys)

        local.subtracting(cloud).forEach { title in
            enqueue {
                LocalStorage.instance.movies[title]!.delete()
            }
        }

        cloud.subtracting(local).forEach { title in
            enqueue {
                self.cloudMovies[title]!.download()
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
