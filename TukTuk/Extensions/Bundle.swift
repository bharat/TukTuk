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
    static var bundles: [String: Bundle] = [:]

    static var cachedMovies: [Movie]?
    static var cachedSongs: [Song]?

    static func media(_ name: String) -> Bundle {
        if !bundles.keys.contains(name) {
            print("Load bundle: \(name)")
            bundles[name] = Bundle(path: "\(Bundle.main.resourcePath!)/Media/\(name)")!
        }
        return bundles[name]!
    }

    func audio(_ name: String) -> URL {
        print("Load audio: \(name)")
        return url(forResource: name, withExtension: "mp3", subdirectory: "Audio")!
    }

    func video(_ name: String) -> URL {
        print("Load video: \(name)")
        return url(forResource: name, withExtension: "mp4", subdirectory: "Video")!
    }

    func songs() -> [Song] {
        if Bundle.cachedSongs == nil {
            let audios = urls(forResourcesWithExtension: "mp3", subdirectory: "Songs")!.sorted(by: { $0.lowerCaseString < $1.lowerCaseString })
            let covers = urls(forResourcesWithExtension: "png", subdirectory: "Songs")!.sorted(by: { $0.lowerCaseString < $1.lowerCaseString })

            assert(audios.count == covers.count)

            Bundle.cachedSongs = zip(audios, covers).map { arg in
                let (audio, cover) = arg
                let fileName = audio.lastPathComponent
                let title = audio.deletingPathExtension().lastPathComponent
                print("Load song: \(title)")
                return try! Song(fileName: fileName, title: title, image: UIImage(data: Data(contentsOf: cover))!, audio: audio)
            }
        }

        return Bundle.cachedSongs!
    }

    func movies() -> [Movie] {
        if Bundle.cachedMovies == nil {
            let path = resourcePath! + "/Video"
            let files = try! FileManager.default.contentsOfDirectory(atPath: path).sorted()

            Bundle.cachedMovies = files.map { name in
                print("Load video: \(name)")
                return Movie(video: url(forAuxiliaryExecutable: "\(path)/\(name)")!, title: (name as NSString).deletingPathExtension)
            }
        }

        return Bundle.cachedMovies!
    }
}

