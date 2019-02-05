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
    static func media(_ name: String) -> Bundle {
        let result = Bundle(path: "\(Bundle.main.resourcePath!)/Media/\(name)")!
        print("Load bundle: \(result)")
        return result
    }

    func audio(_ name: String) -> URL {
        let result = url(forResource: name, withExtension: "mp3", subdirectory: "Audio")!
        print("Load audio: \(result)")
        return result
    }

    func video(_ name: String) -> URL {
        let result = url(forResource: name, withExtension: "mp4", subdirectory: "Video")!
        print("Load video: \(result)")
        return result
    }

    func songs() -> [Song] {
        let audios = urls(forResourcesWithExtension: "mp3", subdirectory: "Songs")!
        let covers = urls(forResourcesWithExtension: "png", subdirectory: "Songs")!

        return zip(audios, covers).map { arg in
            let (audio, cover) = arg
            let song = try! Song(title: audio.lastPathComponent, image: UIImage(data: Data(contentsOf: cover))!, audio: audio)
            print("Load song: \(song)")
            return song
        }
    }

    func videos() -> [Video] {
        let path = resourcePath! + "/Video"
        let files = try! FileManager.default.contentsOfDirectory(atPath: path)

        return files.map { name in
            let video = Video(video: url(forAuxiliaryExecutable: "\(path)/\(name)")!, title: (name as NSString).deletingPathExtension)
            print("Load video: \(video)")
            return video
        }
    }
}

