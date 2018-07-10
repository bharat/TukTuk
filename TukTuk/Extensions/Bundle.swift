//
//  Bundle.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 7/10/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit

extension URL {
    static let Welcome = Bundle.sound("Welcome.mp3")
}

extension FileManager {
    static let songs = {
        try! `default`.contentsOfDirectory(atPath: Bundle.songsPath).filter { $0.hasSuffix(".mp3") }.map { $0 as NSString }
    }()

    static let videos = {
        try! `default`.contentsOfDirectory(atPath: Bundle.videosPath).map { $0 as NSString }
    }()
}

extension Bundle {
    static let songsPath = main.resourcePath! + "/Songs"
    static let videosPath = main.resourcePath! + "/Videos/Normal"

    static func url(from: String) -> URL {
        return main.url(forAuxiliaryExecutable: from)!
    }

    static func sound(_ fileName: String) -> URL {
        return Bundle.url(from: "Sounds/\(fileName)")
    }

    static func video(_ fileName: String) -> URL {
        return Bundle.url(from: "Videos/\(fileName)")
    }

    static let songs: [Song] = FileManager.songs.map {
        let name = $0.deletingPathExtension
        return Song(title: name,
            image: UIImage(named: "Songs/\(name).jpg")!,
            url: Bundle.url(from: "Songs/\(name).mp3"))
    }


    static let videos: [Video] = FileManager.videos.map {
        Video(title: $0.deletingPathExtension, url: Bundle.url(from: "Videos/Normal/\($0)"))
    }
}
