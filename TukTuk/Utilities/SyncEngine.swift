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

    var cloud = CloudSongDict()
    var toDelete: [Song] = []
    var toDownload: [CloudSong] = []
    var totalOperations: Int = 0
    var cancelInProgress: Bool = false
    var notify: ()->() = {}

    var inProgress: Bool {
        return queue.operationCount > 0
    }
    var progress: Float {
        return Float(totalOperations - queue.operationCount) / Float(totalOperations)
    }

    init(concurrency: Int = 4) {
        queue.maxConcurrentOperationCount = concurrency
    }

    func recalculate() {
        let cloudTitles = Set(cloud.keys)
        let localTitles = Set(LocalStorage.instance.songs.keys)

        toDelete = localTitles.subtracting(cloudTitles).map { title in
            LocalStorage.instance.songs[title]!
        }

        toDownload = cloudTitles.subtracting(localTitles).map { title in
            cloud[title]!
        }

        totalOperations = toDelete.count + toDownload.count
    }

    func wrap(block: @escaping ()->()) -> ()->() {
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

    func run() {
        queue.cancelAllOperations()

        toDelete.forEach { song in
            queue.addOperation {
                self.wrap {
                    LocalStorage.instance.delete(song: song)
                }()
            }
        }

        toDownload.forEach { song in
            queue.addOperation {
                self.wrap {
                    if let tempSong = GoogleDrive.instance.download(song: song) {
                        LocalStorage.instance.add(tmpSong: tempSong)
                    }
                }()
            }
        }
    }

    func cancel() {
        cancelInProgress = true
    }
}
