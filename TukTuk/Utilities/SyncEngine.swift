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

    var provider: CloudProvider
    var totalOps: Int = 0
    var cancelInProgress: Bool = false
    var notify: ()->() = {}

    var inProgress: Bool {
        return queue.operationCount > 0
    }
    
    var progress: Float {
        return Float(totalOps - queue.operationCount) / Float(totalOps)
    }

    var inSync: Bool {
        return Songs.instance.inSync && Movies.instance.inSync
    }

    init(cloudProvider: CloudProvider, concurrency: Int = 4) {
        queue.maxConcurrentOperationCount = concurrency
        self.provider = cloudProvider
    }

    func cancel() {
        cancelInProgress = true
    }

    func run(complete: @escaping () -> ()) {
        guard !inProgress else { return }

        let songs = Songs.instance
        songs.delete.forEach { song in
            enqueue { songs.delete(song) }
        }
        songs.download.forEach { song in
            enqueue {
                songs.download(song, from: self.provider)
            }
        }

        let movies = Movies.instance
        movies.delete.forEach { movie in
            enqueue {
                movies.delete(movie)
            }
        }
        movies.download.forEach { movie in
            enqueue {
                movies.download(movie, from: self.provider)
            }
        }
        queue.addOperation {
            complete()
        }
        totalOps = queue.operationCount
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
