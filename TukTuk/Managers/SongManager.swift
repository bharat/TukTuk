//
//  Songs.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 7/10/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation

class SongManager: Manager<Song> {
    static let instance = SongManager()

    fileprivate init() {
        super.init(subdir: "Songs")
    }

    func loadLocal() {
        let names = Set(try! fm.contentsOfDirectory(atPath: base.path).map { fileName in
            NSString(string: fileName).deletingPathExtension
        })
        names.forEach { name in
            let image = LocalFile(url: base.appendingPathComponent("\(name).png"))
            let audio = LocalFile(url: base.appendingPathComponent("\(name).mp3"))
            queue.sync {
                var song = data[name] ?? Song(title: name)
                song.image = image
                song.audio = audio
                data[song.title] = song
            }
        }
    }

    func loadCloud(from provider: CloudProvider) {
        let files = provider.list(folder: provider.songsFolder)

        files?.forEach { file in
            queue.sync {
                var song = data[file.title] ?? Song(title: file.title)
                if file.ext == "mp3" {
                    song.cloudAudio = file
                } else {
                    song.cloudImage = file
                }
                data[song.title] = song
            }
        }
    }

    func download(_ song: Song, from provider: CloudProvider) {
        guard let cloudAudio = song.cloudAudio, let cloudImage = song.cloudImage else { return }
        guard let imageData = provider.get(file: cloudImage.id) else { return }
        guard let audioData = provider.get(file: cloudAudio.id) else { return }

        let image = LocalFile(url: base.appendingPathComponent("\(song.title).png"))
        let audio = LocalFile(url: base.appendingPathComponent("\(song.title).mp3"))
        fm.createNonBackupFile(at: image.url, contents: imageData)
        fm.createNonBackupFile(at: audio.url, contents: audioData)

        queue.sync {
            var song = song
            song.image = image
            song.audio = audio
            data[song.title] = song
        }
    }

    func deleteLocal(_ song: Song) {
        queue.sync {
            if var song = data.removeValue(forKey: song.title) {
                if song.hasCloud {
                    song.audio = nil
                    song.image = nil
                    data[song.title] = song
                }
            }
        }
        [song.image?.url.path, song.audio?.url.path].forEach { path in
            if let path = path {
                try! fm.removeItem(atPath: path)
            }
        }
    }

    func deleteAllLocal() {
        local.forEach { song in
            deleteLocal(song)
        }
    }
}

