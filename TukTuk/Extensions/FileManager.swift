//
//  FileManager.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/8/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation

extension FileManager {
    func excludeFromBackup(_ url: URL) {
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var copy = url
        try! copy.setResourceValues(resourceValues)
    }

    func createNonBackupFile(at url: URL, contents: Data?) {
        createFile(atPath: url.path, contents: contents, attributes: nil)
        excludeFromBackup(url)
    }

    func documentsSubdirectoryUrl(_ pathComponent: String, createIfNecessary: Bool = true) -> URL {
        let url = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(pathComponent)
        if !FileManager.default.fileExists(atPath: url.path) {
            try! FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: false, attributes: nil)
        }
        return url
    }

    func fileSize(_ url: URL) -> UInt64 {
        return try! attributesOfItem(atPath: url.path)[.size] as! UInt64
    }
}
