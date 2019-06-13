//
//  CloudProvider.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/9/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation

struct CloudFile: Hashable {
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

protocol CloudProvider {
    var isAuthenticated: Bool { get }
    var songsFolder: String { get }
    var moviesFolder: String { get }

    func list(folder id: String) -> [CloudFile]?
    func get(file id: String) -> Data?
    func get(files ids: [String]) -> [String:Data?]
    func cancel()
}
