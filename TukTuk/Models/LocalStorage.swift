//
//  LocalSongs.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/5/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation
import UIKit

class LocalStorage {
    static let instance = LocalStorage()
    var songsUrl: URL
    var songs: [String:LocalSong] = [:]
    var moviesUrl: URL
    var movies: [String:LocalMovie] = [:]

    init() {
        songsUrl = FileManager.default.documentsSubdirectoryUrl("Songs")
        moviesUrl = FileManager.default.documentsSubdirectoryUrl("Movies")

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
            songs[title] = LocalSong(title: title, image: imageUrl, audio: audioUrl)
        }
    }
}

struct TempSong {
    var title: String
    var audioData: Data
    var imageData: Data

    func song(_ base: URL) -> LocalSong {
        return LocalSong(title: title, image: imageUrl(base), audio: audioUrl(base))
    }

    func imageUrl(_ base: URL) -> URL {
        return base.appendingPathComponent("\(title).png")
    }

    func audioUrl(_ base: URL) -> URL {
        return base.appendingPathComponent("\(title).mp3")
    }
}

extension LocalStorage {
    func add(_ tmpSong: TempSong) {
        let song = tmpSong.song(songsUrl)
        FileManager.default.createFile(atPath: song.image.path, contents: tmpSong.imageData, attributes: nil)
        FileManager.default.createFile(atPath: song.audio.path, contents: tmpSong.audioData, attributes: nil)
        songs[song.title] = song

        [song.image, song.audio].forEach { url in
            FileManager.default.excludeFromBackup(url)
        }
    }

    func delete(_ song: LocalSong) {
        try! FileManager.default.removeItem(atPath: song.image.path)
        try! FileManager.default.removeItem(atPath: song.audio.path)
        songs.removeValue(forKey: song.title)
    }

    func deleteAllSongs() {
        songs.values.forEach { song in
            delete(song)
        }
    }
}

struct TempMovie {
    var title: String
    var video: Data

    func movie(_ base: URL) -> LocalMovie {
        return LocalMovie(video: base.appendingPathComponent("\(title).mp4"), title: title)
    }
}

extension LocalStorage {
    func add(_ tmp: TempMovie) {
        let movie = tmp.movie(moviesUrl)
        FileManager.default.createFile(atPath: movie.video.path, contents: tmp.video, attributes: nil)
        FileManager.default.excludeFromBackup(movie.video)
        movies[movie.title] = movie

    }

    func delete(_ movie: LocalMovie) {
        try! FileManager.default.removeItem(atPath: movie.video.path)
        movies.removeValue(forKey: movie.title)
    }

    func deleteAllMovies() {
        movies.values.forEach { movie in
            delete(movie)
        }
    }
}
