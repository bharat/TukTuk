//
//  Media.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/3/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation
import UIKit

class Media {
    static let Player = Media("Player")
    var bundle: Bundle!

    init(_ name: String) {
        self.bundle = Bundle(path: "\(Bundle.main.resourcePath!)/Media/\(name)")!
    }

    func sound(_ name: String) -> Sound {
        return Sound(url: bundle.url(forResource: name, withExtension: "mp3", subdirectory: "Audio")!)
    }

    func video(_ name: String) -> URL {
        return bundle.url(forResource: name, withExtension: "mp4", subdirectory: "Video")!
    }

    func play(_ name: String, for child: Child?) {
        if let child = child {
            sound("\(name)_\(child.name)").play()
        }
    }
}
