//
//  Songs.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 7/10/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation

extension Manager where T == Song {
    static let songs = SongManager()
}

class SongManager: Manager<Song> {
    fileprivate init() {
        super.init(subdir: "Songs")
    }

    var brokenCloud: [Song] {
        return queue.sync {
            data.values.filter { song in
                (song.cloudAudio == nil && song.cloudImage != nil) || (song.cloudAudio != nil && song.cloudImage == nil)
            }
        }
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
        cloud.forEach { song in
            queue.sync {
                self.data[song.title]?.cloudAudio = nil
                self.data[song.title]?.cloudImage = nil
            }
        }

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
}

