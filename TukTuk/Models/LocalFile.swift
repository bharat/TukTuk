//
//  LocalFile.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/12/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation

struct LocalFile {
    var url: URL

    var exists: Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }

    var size: UInt64 {
        return FileManager.default.fileSize(url)
    }

    func delete() {
        if exists {
            try! FileManager.default.removeItem(atPath: url.path)
        }
    }
}
