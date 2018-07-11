//
//  Bundle.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 7/10/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit

extension FileManager {
    static let songNames = {
        Set(try! `default`.contentsOfDirectory(atPath: Bundle.songsPath).map { ($0 as NSString).deletingPathExtension })
    }()

    static let videoNames = {
        try! `default`.contentsOfDirectory(atPath: Bundle.videosPath).map { ($0 as NSString).deletingPathExtension }
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

    static let songs: [Song] = FileManager.songNames.map { name in
        return Song(title: name,
            image: UIImage(named: "Songs/\(name).jpg")!,
            url: Bundle.url(from: "Songs/\(name).mp3"))
    }.shuffled()


    static let videos: [Video] = FileManager.videoNames.map { name in
        Video(title: name, url: Bundle.url(from: "Videos/Normal/\(name).mp4"))
    }
}
