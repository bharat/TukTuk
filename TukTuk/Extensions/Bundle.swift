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

    static func media(_ name: String) -> Bundle {
        if !bundles.keys.contains(name) {
            bundles[name] = Bundle(path: "\(Bundle.main.resourcePath!)/Media/\(name)")!
        }
        print("Load bundle: \(name)")
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
        let audios = urls(forResourcesWithExtension: "mp3", subdirectory: "Songs")!
        let covers = urls(forResourcesWithExtension: "png", subdirectory: "Songs")!

        return zip(audios, covers).map { arg in
            let (audio, cover) = arg
            let title = audio.lastPathComponent
            print("Load song: \(title)")
            return try! Song(title: title, image: UIImage(data: Data(contentsOf: cover))!, audio: audio)
        }
    }

    func videos() -> [Video] {
        let path = resourcePath! + "/Video"
        let files = try! FileManager.default.contentsOfDirectory(atPath: path)

        return files.map { name in
            print("Load video: \(name)")
            return Video(video: url(forAuxiliaryExecutable: "\(path)/\(name)")!, title: (name as NSString).deletingPathExtension)
        }
    }
}

