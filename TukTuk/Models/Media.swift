//
//  Media.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/3/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation
import UIKit

class Media {
    static let Player = PlayerMedia()
    var bundle: Bundle!

    init(_ name: String) {
        self.bundle = Bundle(path: "\(Bundle.main.resourcePath!)/Media/\(name)")!
    }

    func audio(_ name: String) -> URL {
        return bundle.url(forResource: name, withExtension: "mp3", subdirectory: "Audio")!
    }

    func video(_ name: String) -> URL {
        return bundle.url(forResource: name, withExtension: "mp4", subdirectory: "Video")!
    }
}

class PlayerMedia: Media {
    var songs: [Song]!
    var movies: [Movie]!

    init() {
        super.init("Player")

        let audios = bundle.urls(forResourcesWithExtension: "mp3", subdirectory: "Songs")!.sorted(by: { $0.lowerCaseString < $1.lowerCaseString })
        let covers = bundle.urls(forResourcesWithExtension: "png", subdirectory: "Songs")!.sorted(by: { $0.lowerCaseString < $1.lowerCaseString })

        assert(audios.count == covers.count)

        songs = zip(audios, covers).map { arg in
            let (audio, cover) = arg
            let fileName = audio.lastPathComponent
            let title = audio.deletingPathExtension().lastPathComponent
            print("Load song: \(title)")
            return try! Song(fileName: fileName, title: title, image: UIImage(data: Data(contentsOf: cover))!, audio: audio)
        }

        let path = bundle.resourcePath! + "/Video"
        let files = try! FileManager.default.contentsOfDirectory(atPath: path).sorted()

        movies = files.map { name in
            print("Load video: \(name)")
            return Movie(video: bundle.url(forAuxiliaryExecutable: "\(path)/\(name)")!, title: (name as NSString).deletingPathExtension)
        }
    }
}
