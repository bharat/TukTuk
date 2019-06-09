//
//  Movie.Local.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 7/10/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation

struct Movie {
}

extension Movie {
    struct Local: VideoPlayable, Titled, Deletable {
        var video: URL
        var title: String

        func delete() {
            LocalStorage.instance.delete(self)
        }
    }
    typealias LocalDict = [String:Movie.Local]
}

extension Movie {
    struct Cloud: Downloadable {
        var title: String
        var id: String
        var provider: CloudProvider

        func download() {
            if let tmp = provider.download(self) {
                LocalStorage.instance.add(tmp)
            }
        }
    }
    typealias CloudDict = [String:Movie.Cloud]
}

extension Movie {
    struct Temporary {
        var title: String
        var video: Data

        func movie(_ base: URL) -> Movie.Local {
            return Movie.Local(video: base.appendingPathComponent("\(title).mp4"), title: title)
        }
    }
}
