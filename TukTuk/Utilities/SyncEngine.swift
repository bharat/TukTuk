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
    var cancelers = [Canceler]()
    var notify: ()->() = {}

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
        syncQueue.async {
            self.cancelRequested = true
            self.cancelers.forEach { canceler in
                canceler.cancel()
            }
            self.cancelers.removeAll()
        }
    }

    func run(complete: @escaping ()->()) {
        guard inProgress == false else { return }

        let songs = SongManager.instance
        let movies = MovieManager.instance

        songs.delete.forEach { song in
            opQueue.addOperation {
                songs.deleteLocal(song)
                self.notify()
            }
        }

        movies.delete.forEach { movie in
            opQueue.addOperation {
                movies.deleteLocal(movie)
                self.notify()
            }
        }

        songs.download.forEach { song in
            opQueue.addOperation {
                self.wrap { callback in
                    return songs.download(song, from: self.provider) {
                        callback()
                    }
                }
            }
        }

        movies.download.forEach { movie in
            opQueue.addOperation {
                self.wrap { callback in
                    return movies.download(movie, from: self.provider) {
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
        let cancelRequested = self.syncQueue.sync {
            return self.cancelRequested
        }

        guard cancelRequested == false else {
            return
        }

        let group = DispatchGroup()
        group.enter()
        let canceler = block {
            self.notify()
            group.leave()
        }

        if let canceler = canceler {
            self.syncQueue.sync {
                self.cancelers.append(canceler)
            }
        }

        while group.wait(timeout: .now() + 1.0) == .timedOut {
            let cancelRequested = self.syncQueue.sync {
                return self.cancelRequested
            }
            if cancelRequested {
                return
            }
        }
    }
}
