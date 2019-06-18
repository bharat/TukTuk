//
//  SyncEngine.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/6/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation

class SyncEngine {
    private let opQueue = OperationQueue()
    private let syncQueue = DispatchQueue(label: "SyncEngine")

    var provider: CloudProvider
    var totalOps: Int = 0
    var cancelRequested = false
    var notifyStart: (String)->() = { _ in }
    var notifyStop: (String)->() = { _ in }

    var inProgress: Bool {
        return opQueue.operationCount > 0
    }
    
    var progress: Float {
        return Float(totalOps - opQueue.operationCount) / Float(totalOps)
    }

    var inSync: Bool {
        return SongManager.instance.inSync && MovieManager.instance.inSync
    }

    init(cloudProvider: CloudProvider, concurrency: Int = 4) {
        opQueue.maxConcurrentOperationCount = concurrency
        self.provider = cloudProvider
    }

    func cancel() {
        syncQueue.sync {
            self.cancelRequested = true
        }
    }

    func run(complete: @escaping ()->()) {
        guard inProgress == false else { return }

        let songs = SongManager.instance
        let movies = MovieManager.instance

        songs.delete.forEach { song in
            opQueue.addOperation {
                songs.deleteLocal(song)
            }
        }

        movies.delete.forEach { movie in
            opQueue.addOperation {
                movies.deleteLocal(movie)
            }
        }

        songs.download.forEach { song in
            opQueue.addOperation {
                self.wrap { callback in
                    let msg = "Download song: \(song.title)"
                    self.notifyStart(msg)
                    return songs.download(song, from: self.provider) {
                        self.notifyStop(msg)
                        callback()
                    }
                }
            }
        }

        movies.download.forEach { movie in
            opQueue.addOperation {
                self.wrap { callback in
                    let msg = "Download movie: \(movie.title)"
                    self.notifyStart(msg)
                    return movies.download(movie, from: self.provider) {
                        self.notifyStop(msg)
                        callback()
                    }
                }
            }
        }

        DispatchQueue.global().async {
            self.opQueue.waitUntilAllOperationsAreFinished()
            self.syncQueue.sync {
                self.cancelRequested = false
            }
            complete()
        }

        totalOps = opQueue.operationCount
    }

    func wrap(block: (_ callback: @escaping ()->())->(Canceler?)) {
        let cancelRequested = syncQueue.sync {
            return self.cancelRequested
        }
        guard cancelRequested == false else { return }

        let group = DispatchGroup()
        group.enter()
        let canceler = block {
            group.leave()
        }

        while group.wait(timeout: .now() + 1.0) == .timedOut {
            let cancelRequested = syncQueue.sync {
                return self.cancelRequested
            }

            if cancelRequested {
                canceler?.cancel()
                return
            }
        }
    }
}
