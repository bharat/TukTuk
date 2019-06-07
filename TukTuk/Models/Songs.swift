//
//  Songs.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/5/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation
import UIKit

class Songs {
    static let instance = Songs()
    var songs: [Song]! = []
    var songsChangedSinceLastDisplay: Bool = true
    var songsUrl: URL

    init() {
        songsUrl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("Songs")
        if !FileManager.default.fileExists(atPath: songsUrl.path) {
            try? FileManager.default.createDirectory(atPath: songsUrl.path, withIntermediateDirectories: false, attributes: nil)
        }

        load()
    }

    func load() {
        songs = []
        let fileNames = try! FileManager.default.contentsOfDirectory(atPath: songsUrl.path)
        let titles = Set(fileNames.map { fileName in
            NSString(string: fileName).deletingPathExtension
        })
        songs = titles.map { title in
            let imageFile = songsUrl.appendingPathComponent("\(title).png").path
            let audioUrl = songsUrl.appendingPathComponent("\(title).mp3")
            return Song(title: title, image: UIImage(contentsOfFile: imageFile)!, audio: audioUrl)
        }
    }

    func add(title: String, audioData: Data, imageData: Data) {
        FileManager.default.createFile(atPath: "\(songsUrl.path)/\(title).png", contents: imageData, attributes: nil)
        FileManager.default.createFile(atPath: "\(songsUrl.path)/\(title).mp3", contents: audioData, attributes: nil)

        load()
    }

    func remove(title: String) {
        try! FileManager.default.removeItem(atPath: "\(songsUrl.path)/\(title).png")
        try! FileManager.default.removeItem(atPath: "\(songsUrl.path)/\(title).mp3")
        songs = songs.filter { $0.title != title }
    }

    func removeAll() {
        songs.map { $0.title }.forEach {
            remove(title: $0)
        }
    }
}
