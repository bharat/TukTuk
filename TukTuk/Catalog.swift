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
    var music: URL
}

struct Video {
    var title: String
    var video: URL
}

// TODO: this class needs to be refactored
class Catalog {
    static var instance = Catalog()

    var songs: [Song] = []
    var videos: [Video] = []

    var welcomeSong: URL {
        return Bundle.main.url(forAuxiliaryExecutable: "Welcome/welcome.mp3")!
    }

    private init() {
        // Load the music catalog
        let catalogUrl = Bundle.main.url(forAuxiliaryExecutable: "Meta/catalog.txt")
        let catalog = try! String(contentsOf: catalogUrl!, encoding: .utf8).components(separatedBy: "\n")
        songs = []
        for i in 0..<catalog.count/2 {
            songs.append(Song(
                image: UIImage(named: "Songs/\(catalog[2*i])")!,
                music: Bundle.main.url(forAuxiliaryExecutable: "Songs/\(catalog[2*i+1])")!))
        }

        // Load the "surprise" video catalog
        for s in try! FileManager.default.contentsOfDirectory(
            atPath: Bundle.main.resourcePath! + "/Videos") {
                videos.append(Video(title: s, video: Bundle.main.url(forAuxiliaryExecutable: "Videos/\(s)")!))
        }
    }


}
