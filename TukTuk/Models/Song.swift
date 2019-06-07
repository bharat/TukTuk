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
    var image: UIImage
    var audio: URL
}
