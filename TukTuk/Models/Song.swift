//
//  Song.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 7/10/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit

struct Song: AudioPlayable, Titled {
    var title: String
    var imageUrl: URL
    var audioUrl: URL

    var image: UIImage {
        return UIImage(contentsOfFile: imagePath)!
    }

    var audioPath: String {
        return audioUrl.path
    }

    var imagePath: String {
        return imageUrl.path
    }
}

typealias LocalSongDict = [String:Song]
