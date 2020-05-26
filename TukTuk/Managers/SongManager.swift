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
            // TODO: this doesn't handle inconsistencies with missing or malformed cloud video
            data.values.filter { song in
                !song.hasWellFormedCloud
            }
        }
    }

    func loadLocal() {
        let names = Set(try! fm.contentsOfDirectory(atPath: base.path).map { fileName in
            NSString(string: fileName).deletingPathExtension
        })
        names.forEach {
            let name = $0.replacingOccurrences(of: "%2F", with: "/")
            let image = LocalFile(url: base.appendingPathComponent("\($0).png"))
            let audio = LocalFile(url: base.appendingPathComponent("\($0).mp3"))
            let video = LocalFile(url: base.appendingPathComponent("\($0).mp4"))
            queue.sync {
                var song = data[name] ?? Song(title: name)
                song.image = image
                song.audio = audio
                song.video = video
                data[song.title] = song
            }
        }
    }

    func loadCloud(from provider: CloudProvider, notify: @escaping () -> ()) {
        cloud.forEach { song in
            queue.sync {
                self.data[song.title]?.cloudAudio = nil
                self.data[song.title]?.cloudImage = nil
                self.data[song.title]?.cloudVideo = nil
            }
        }

        provider.list(folder: provider.songsFolder) { files in
            self.queue.sync {
                files.forEach { file in
                    var song = self.data[file.title] ?? Song(title: file.title)
                    switch file.ext {
                    case "mp3":
                        song.cloudAudio = file
                    case "mp4":
                        song.cloudVideo = file
                    default:
                        song.cloudImage = file
                    }
                    self.data[song.title] = song
                }
            }
            notify()
        }
    }

    func download(_ song: Song, from provider: CloudProvider, notify: @escaping () -> ()) -> Canceler? {
        guard song.hasWellFormedCloud else { return nil }

        // Call notify() once after both downloads complete
        var doneCount = 0
        let notifyWrapper = {
            doneCount += 1
            if doneCount == 2 {
                notify()
            }
        }

        let safeTitle = song.title.replacingOccurrences(of: "/", with: "%2F")
        let canceler1 = provider.get(file: song.cloudImage!.id) { cloudData in
            if let cloudData = cloudData {
                let local = LocalFile(url: self.base.appendingPathComponent("\(safeTitle).png"))
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
                let local = LocalFile(url: self.base.appendingPathComponent("\(safeTitle).mp3"))
                self.fm.createNonBackupFile(at: local.url, contents: cloudData)

                self.queue.sync {
                    var song = self.data[song.title] ?? Song(title: song.title)
                    song.audio = local
                    self.data[song.title] = song
                }
            }
            notifyWrapper()
        }
        var cancelers = [canceler1, canceler2]

        if let cloudVideo = song.cloudVideo {
            let canceler3 = provider.get(file: cloudVideo.id) { cloudData in
                if let cloudData = cloudData {
                    let local = LocalFile(url: self.base.appendingPathComponent("\(safeTitle).mp4"))
                    self.fm.createNonBackupFile(at: local.url, contents: cloudData)

                    self.queue.sync {
                        var song = self.data[song.title] ?? Song(title: song.title)
                        song.video = local
                        self.data[song.title] = song
                    }
                }
                notifyWrapper()
            }
            cancelers += [canceler3]
        }

        return CancelGroup(cancelers: cancelers)
    }
}

