//
//  Child.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 12/30/23.
//  Copyright © 2023 Menalto. All rights reserved.
//

import Foundation
import UIKit

struct Child: Equatable {
    var name: String
    var image: UIImage
    var songsFolderId: String
    var moviesFolderId: String
    var imagesFolderId: String
}

class Children {
    static var all: [Child] = [
        Child(name: "Remy", image: UIImage(named: "AppIcon_Remy")!, songsFolderId: "1cE63ZqcSU8cY6nnZ7RPG4Z5EPV0nwuMz", moviesFolderId: "1vbYHlO5bQbym9g8wSg8GYlF42-LMIv2W", imagesFolderId: "1bldR2at2O3RdSLQYu9OQaizcdjs7MxFo"),
        Child(name: "Maryse", image: UIImage(named: "AppIcon_Maryse")!, songsFolderId: "1RzHgHCfvXB_0AutKblmCW48ilqe7yRR7", moviesFolderId: "1PgpU3qJPcBi67AIxwuHWCWs85zpDQipw", imagesFolderId: "1IxjPhWKbi5V5m5JyDTmlDLx1IsS-RGpa")
    ]
}
