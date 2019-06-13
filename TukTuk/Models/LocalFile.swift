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

    var size: UInt64 {
        return FileManager.default.fileSize(url)
    }
}
