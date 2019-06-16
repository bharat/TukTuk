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

    func loadCloud(from provider: CloudProvider, notify: @escaping () -> ()) {
        provider.list(folder: provider.songsFolder) { files in
            self.queue.sync {
                files.forEach { file in
                    var song = self.data[file.title] ?? Song(title: file.title)
                    if file.ext == "mp3" {
                        song.cloudAudio = file
                    } else {
                        song.cloudImage = file
                    }
                    self.data[song.title] = song
                }
            }
            notify()
        }
    }

    func download(_ song: Song, from provider: CloudProvider, notify: @escaping () -> ()) -> Canceler? {
        guard song.hasCloud else { return nil }

        // Call notify() once after both downloads complete
        var doneCount = 0
        let notifyWrapper = {
            doneCount += 1
            if doneCount == 2 {
                notify()
            }
        }

        let canceler1 = provider.get(file: song.cloudImage!.id) { cloudData in
            if let cloudData = cloudData {
                let local = LocalFile(url: self.base.appendingPathComponent("\(song.title).png"))
                self.fm.createNonBackupFile(at: local.url, contents: cloudData)

                self.queue.sync {
                    var song = self.data[song.title] ?? Song(title: song.title)
                    song.image = local
                    self.data[song.title] = song
                }
            }
            notifyWrapper()
        }

        let canceler2 = provider.get(file: song.cloudAudio!.id) { cloudData in
            if let cloudData = cloudData {
                let local = LocalFile(url: self.base.appendingPathComponent("\(song.title).mp3"))
                self.fm.createNonBackupFile(at: local.url, contents: cloudData)

                self.queue.sync {
                    var song = self.data[song.title] ?? Song(title: song.title)
                    song.audio = local
                    self.data[song.title] = song
                }
            }
            notifyWrapper()
        }

        return CancelGroup(cancelers: [canceler1, canceler2])
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
                try? fm.removeItem(atPath: path)
            }
        }
    }

    func deleteAllLocal() {
        data.values.forEach { song in
            deleteLocal(song)
        }
    }
}

