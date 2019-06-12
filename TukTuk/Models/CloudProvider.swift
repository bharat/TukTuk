//
//  CloudProvider.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/9/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation

struct CloudFile {
    let name: String
    let id: String
    let size: NSNumber
}

protocol CloudProvider {
    var isAuthenticated: Bool { get }
    var songsFolder: String { get }
    var moviesFolder: String { get }

    func list(folder id: String) -> [CloudFile]?
    func get(file id: String) -> Data?
    func get(files ids: [String]) -> [String:Data?]
}
