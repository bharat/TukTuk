//
//  LocalSong.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 7/10/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit

struct LocalSong: AudioPlayable, Titled {
    var title: String
    var image: URL
    var audio: URL

    var uiImage: UIImage {
        return UIImage(contentsOfFile: image.path)!
    }
}

typealias LocalSongDict = [String:LocalSong]
