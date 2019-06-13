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
    var cancelRequested: Bool = false
    var notify: ()->() = {}

    var inProgress: Bool {
        return queue.operationCount > 0
    }
    
    var progress: Float {
        return Float(totalOps - queue.operationCount) / Float(totalOps)
    }

    var inSync: Bool {
        return SongManager.instance.inSync && MovieManager.instance.inSync
    }

    init(cloudProvider: CloudProvider, concurrency: Int = 4) {
        queue.maxConcurrentOperationCount = concurrency
        self.provider = cloudProvider
    }

    func cancel() {
        cancelRequested = true
    }

    func run() {
        guard !inProgress else { return }

        let songs = SongManager.instance
        let movies = MovieManager.instance

        var blocks = [()->()]()
        blocks += songs.delete.map    { song  in { songs.deleteLocal(song)                     } }
        blocks += songs.download.map  { song  in { songs.download(song, from: self.provider)   } }
        blocks += movies.delete.map   { movie in { movies.deleteLocal(movie)                   } }
        blocks += movies.download.map { movie in { movies.download(movie, from: self.provider) } }

        blocks.forEach { block in
            queue.addOperation {
                if !self.cancelRequested {
                    block()
                }

                if self.queue.operationCount == 1 {
                    self.cancelRequested = false
                }

                self.notify()
            }
        }
        totalOps = queue.operationCount
    }
}
