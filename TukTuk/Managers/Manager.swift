//
//  Manager.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/12/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation

protocol Manageable: Titled {
    var hasLocal: Bool { get }
    var hasCloud: Bool { get }
    var syncAction: SyncAction { get }
    mutating func deleteLocal()
}

class Manager<T: Manageable> {
    let queue = DispatchQueue(label: "worker")
    let base: URL
    let fm = FileManager.default
    var data = [String:T]()

    init(subdir: String) {
        base = fm.documentsSubdirectoryUrl(subdir)
    }

    var inSync: Bool {
        return cloud.count > 0 && queue.sync {
            data.values.filter { $0.syncAction != .None }.count == 0
        }
    }

    var download: [T] {
        return queue.sync {
            data.values.filter { $0.syncAction == .Download }
        }
    }

    var delete: [T] {
        return queue.sync {
            data.values.filter { $0.syncAction == .Delete }
        }
    }

    var local: [T] {
        return queue.sync {
            data.values.filter { $0.hasLocal }
        }
    }

    var cloud: [T] {
        return queue.sync {
            data.values.filter { $0.hasCloud }
        }
    }

    var localEmpty: Bool {
        return local.count == 0
    }

    func deleteLocal(_ obj: T) {
        queue.sync {
            if var obj = data.removeValue(forKey: obj.title) {
                obj.deleteLocal()
                if obj.hasCloud {
                    data[obj.title] = obj
                }
            }
        }
    }

    func deleteAllLocal() {
        data.values.forEach { obj in
            deleteLocal(obj)
        }
    }
}
