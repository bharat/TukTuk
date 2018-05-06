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

class Catalog {
    static var `default` = Catalog()

    var songs: [Song] = []
    var surprises: [Surprise] = []

    var welcomeSong: URL {
        return Bundle.main.url(forAuxiliaryExecutable: "Meta/welcome.mp3")!
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
            atPath: Bundle.main.resourcePath! + "/Surprises") {
                surprises.append(Surprise(title: s, movie: Bundle.main.url(forAuxiliaryExecutable: "Surprises/\(s)")!))
        }
    }


}
