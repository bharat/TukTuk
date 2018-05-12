//
//  Catalog.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/6/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit

struct Song {
    var image: UIImage
    var audio: URL
}

struct Movie {
    var title: String
    var video: URL
}

// TODO: this class needs to be refactored
class Catalog {
    static var instance = Catalog()

    var songs: [Song] = []
    var videos: [Movie] = []

    private init() {
        let catalogUrl = url(from: "Meta/catalog.txt")
        let catalog = try! String(contentsOf: catalogUrl, encoding: .utf8).components(separatedBy: "\n")
        songs = []
        for i in 0..<catalog.count/2 {
            songs.append(Song(
                image: UIImage(named: "Songs/\(catalog[2*i])")!,
                audio: url(from: "Songs/\(catalog[2*i+1])")))
        }

        for s in try! FileManager.default.contentsOfDirectory(
            atPath: Bundle.main.resourcePath! + "/Videos") {
                videos.append(Movie(title: s, video: url(from: "Videos/\(s)")))
        }
    }

    static func sound(from fileName: String) -> URL {
        return instance.url(from: "Sounds/\(fileName)")
    }

    func url(from: String) -> URL {
        return Bundle.main.url(forAuxiliaryExecutable: from)!
    }
}
