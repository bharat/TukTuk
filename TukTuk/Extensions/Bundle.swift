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

    static func sound(for name: String) -> URL {
        return main.url(forAuxiliaryExecutable: "Sounds/\(name).mp3")!
    }

    static func song(for name: String) -> URL {
        return main.url(forAuxiliaryExecutable:  "Songs/\(name).mp3")!
    }

    static func song(for name: String) -> UIImage {
        return UIImage(named: "Songs/\(name).png") ?? UIImage(named: "Songs/\(name).jpg")!
    }

    static func video(for name: String) -> URL {
        return main.url(forAuxiliaryExecutable:  "Videos/\(name).mp4")!
    }

    static let songs: [Song] = FileManager.songNames.map { name in
        return Song(title: name,
                    image: song(for: name),
                    url: song(for: name))
    }.shuffled()


    static let videos: [Video] = FileManager.videoNames.map { name in
        Video(title: name, url: video(for: "Normal/\(name)"))
    }
}
