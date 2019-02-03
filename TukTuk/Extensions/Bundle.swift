//
//  Bundle.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 7/10/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit

extension Bundle {
    static func preload() {
        // Just referencing songs and videos will force them to load
        print("Loaded \(songs.count) songs and \(videos.count) videos")
    }

    static func sound(for name: String) -> URL {
        return main.url(forAuxiliaryExecutable: "Sounds/\(name).mp3")!
    }

    static func video(for name: String) -> URL {
        return main.url(forAuxiliaryExecutable: "Videos/\(name).mp4")!
    }

    static let songs: [Song] = {
        let path = "\(main.resourcePath!)/Songs"
        let files = try! FileManager.default.contentsOfDirectory(atPath: path)
        let titles = Set(files.map { ($0 as NSString).deletingPathExtension })
        return titles.map { name in
            Song(title: name,
                 image: UIImage(named: "Songs/\(name).png")!,
                 url: main.url(forAuxiliaryExecutable:  "\(path)/\(name).mp3")!)
        }.shuffled()
    }()

    static let videos: [Video] = {
        let path = "\(main.resourcePath!)/Videos/Normal"
        let files = try! FileManager.default.contentsOfDirectory(atPath: path).sorted()

        return files.map { name in
            Video(url: main.url(forAuxiliaryExecutable: "\(path)/\(name)")!, title: (name as NSString).deletingPathExtension)
        }
    }()
}
