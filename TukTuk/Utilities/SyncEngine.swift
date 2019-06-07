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
    static let instance = SyncEngine()

    init(concurrency: Int = 4) {
        queue.maxConcurrentOperationCount = concurrency
    }

    func start(notify: @escaping () -> ()) {
        let local = Set(Songs.instance.songs.map { $0.title })
        let cloud = Set(GoogleDrive.instance.songs.keys)

        local.subtracting(cloud).forEach { title in
            queue.addOperation {
                Songs.instance.remove(title: title)
                notify()
            }
        }

        cloud.subtracting(local).forEach { title in
            queue.addOperation {
                GoogleDrive.instance.downloadSong(title: title)
                notify()
            }
        }
    }
}
