//
//  Song.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 7/10/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit

struct Song {
}

extension Song {
    struct Local: AudioPlayable, Titled, Deletable {
        var title: String
        var image: URL
        var audio: URL

        var uiImage: UIImage {
            return UIImage(contentsOfFile: image.path)!
        }

        func delete() {
            LocalStorage.instance.delete(self)
        }
    }
    typealias LocalDict = [String:Song.Local]
}

extension Song {
    struct Cloud: Downloadable {
        var title: String
        var audioId: String
        var imageId: String
        var provider: CloudProvider

        func download() {
            if let tmp = provider.download(self) {
                LocalStorage.instance.add(tmp)
            }
        }
    }
    typealias CloudDict = [String:Song.Cloud]
}

extension Song {
    struct Temporary {
        var title: String
        var audioData: Data
        var imageData: Data

        func song(_ base: URL) -> Song.Local {
            return Song.Local(title: title, image: imageUrl(base), audio: audioUrl(base))
        }

        func imageUrl(_ base: URL) -> URL {
            return base.appendingPathComponent("\(title).png")
        }

        func audioUrl(_ base: URL) -> URL {
            return base.appendingPathComponent("\(title).mp3")
        }
    }
}
