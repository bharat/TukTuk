//
//  LocalSongs.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/5/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation
import UIKit

struct TempSong {
    var title: String
    var audioData: Data
    var imageData: Data

    func song(_ base: URL) -> Song {
        return Song(title: title, imageUrl: imageUrl(base), audioUrl: audioUrl(base))
    }

    func imageUrl(_ base: URL) -> URL {
        return base.appendingPathComponent("\(title).png")
    }

    func audioUrl(_ base: URL) -> URL {
        return base.appendingPathComponent("\(title).mp3")
    }
}

class LocalStorage {
    static let instance = LocalStorage()
    var songs: [String:Song]! = [:]
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
        songs = [:]
        let fileNames = try! FileManager.default.contentsOfDirectory(atPath: songsUrl.path)
        let titles = Set(fileNames.map { fileName in
            NSString(string: fileName).deletingPathExtension
        })
        titles.forEach { title in
            let imageUrl = songsUrl.appendingPathComponent("\(title).png")
            let audioUrl = songsUrl.appendingPathComponent("\(title).mp3")
            songs[title] = Song(title: title, imageUrl: imageUrl, audioUrl: audioUrl)
        }
    }

    func add(tmpSong: TempSong) {
        let song = tmpSong.song(songsUrl)
        FileManager.default.createFile(atPath: song.imageUrl.path, contents: tmpSong.imageData, attributes: nil)
        FileManager.default.createFile(atPath: song.audioUrl.path, contents: tmpSong.audioData, attributes: nil)
        songs[song.title] = song
    }

    func delete(song: Song) {
        try! FileManager.default.removeItem(atPath: song.imagePath)
        try! FileManager.default.removeItem(atPath: song.audioPath)
        songs.removeValue(forKey: song.title)
    }

    func deleteAllSongs() {
        songs.values.forEach { song in
            delete(song: song)
        }
    }
}
