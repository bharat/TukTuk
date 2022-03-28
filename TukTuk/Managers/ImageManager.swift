//
//  ImageManager.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 3/27/22.
//  Copyright © 2022 Menalto. All rights reserved.
//

import Foundation

extension Manager where T == Image {
    static let images = ImageManager()
}

class ImageManager: Manager<Image> {
    fileprivate init() {
        super.init(subdir: "Images")
    }

    var brokenCloud: [Image] {
        return queue.sync {
            data.values.filter { image in
                !image.hasWellFormedCloud
            }
        }
    }

    func loadLocal() {
        let names = Set(try! fm.contentsOfDirectory(atPath: base.path).map { fileName in
            NSString(string: fileName).deletingPathExtension
        })
        names.forEach {
            let name = $0.replacingOccurrences(of: "%2F", with: "/")
            let actual_image = LocalFile(url: base.appendingPathComponent("\($0).jpg"))
            queue.sync {
                var image = Image(title: name)
                image.image = actual_image
                data[image.title] = image
            }
        }
    }

    func loadCloud(from provider: CloudProvider, notify: @escaping () -> ()) {
        cloud.forEach { image in
            queue.sync {
                self.data[image.title]?.cloudImage = nil
            }
        }

        provider.list(folder: provider.songsFolder) { files in
            self.queue.sync {
                files.forEach { file in
                    var image = self.data[file.title] ?? Image(title: file.title)
                    image.cloudImage = file
                    self.data[image.title] = image
                }
            }
            notify()
        }
    }

    func download(_ image: Image, from provider: CloudProvider, notify: @escaping () -> ()) -> Canceler? {
        guard image.hasWellFormedCloud else { return nil }

        let safeTitle = image.title.replacingOccurrences(of: "/", with: "%2F")
        let canceler = provider.get(file: image.cloudImage!.id) { cloudData in
            if let cloudData = cloudData {
                let local = LocalFile(url: self.base.appendingPathComponent("\(safeTitle).jpg"))
                self.fm.createNonBackupFile(at: local.url, contents: cloudData)

                self.queue.sync {
                    var image = self.data[image.title] ?? Image(title: image.title)
                    image.image = local
                    self.data[image.title] = image
                }
            }
            notify()
        }

        return CancelGroup(cancelers: [canceler])
    }
}

