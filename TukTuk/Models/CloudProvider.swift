//
//  CloudProvider.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/9/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation

protocol CloudFileProtocol {
    var name: String { get }
    var id: String { get }
    var size: UInt64 { get }
    var title: String { get }
    var ext: String { get }
}

struct CloudFile: CloudFileProtocol, Hashable {
    let name: String
    let id: String
    let size: UInt64

    var title: String {
        return NSString(string: name).deletingPathExtension
    }

    var ext: String {
        return NSString(string: name).pathExtension
    }
}

protocol Canceler {
    func cancel()
}

struct CancelGroup: Canceler {
    var cancelers: [Canceler]

    func cancel() {
        cancelers.forEach { canceler in
            canceler.cancel()
        }
    }
}

protocol CloudProvider {
    var isAuthenticated: Bool { get }
    var songsFolder: String { get }
    var moviesFolder: String { get }

    func list(folder id: String, callback: @escaping ([CloudFile])->())
    func get(file id: String, callback: @escaping (Data?)->()) -> Canceler
}
