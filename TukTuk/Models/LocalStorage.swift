//
//  Song.Locals.swift
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
    var songs = Song.LocalDict()
    var moviesUrl: URL
    var movies = Movie.LocalDict()

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
            songs[title] = Song.Local(title: title, image: imageUrl, audio: audioUrl)
        }

        movies = [:]
        try! FileManager.default.contentsOfDirectory(atPath: moviesUrl.path).forEach { fileName in
            let title = NSString(string: fileName).deletingPathExtension
            movies[title] = Movie.Local(video: moviesUrl.appendingPathComponent(fileName), title: title)
        }
    }
}

extension LocalStorage {
    func add(_ tmp: Song.Temporary) {
        let song = tmp.song(songsUrl)
        FileManager.default.createFile(atPath: song.image.path, contents: tmp.imageData, attributes: nil)
        FileManager.default.createFile(atPath: song.audio.path, contents: tmp.audioData, attributes: nil)
        songs[song.title] = song

        [song.image, song.audio].forEach { url in
            FileManager.default.excludeFromBackup(url)
        }
    }

    func delete(_ song: Song.Local) {
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


extension LocalStorage {
    func add(_ tmp: Movie.Temporary) {
        let movie = tmp.movie(moviesUrl)
        FileManager.default.createFile(atPath: movie.video.path, contents: tmp.video, attributes: nil)
        FileManager.default.excludeFromBackup(movie.video)
        movies[movie.title] = movie

    }

    func delete(_ movie: Movie.Local) {
        try! FileManager.default.removeItem(atPath: movie.video.path)
        movies.removeValue(forKey: movie.title)
    }

    func deleteAllMovies() {
        movies.values.forEach { movie in
            delete(movie)
        }
    }
}
