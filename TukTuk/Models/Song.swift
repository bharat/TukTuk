//
//  Song.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/12/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation
import UIKit

struct Song: Manageable {
    var title: String
    var image: LocalFile?
    var audio: LocalFile?
    var cloudImage: CloudFile?
    var cloudAudio: CloudFile?

    var hasLocal: Bool {
        return image != nil && image!.exists && audio != nil && audio!.exists
    }

    var hasCloud: Bool {
        return cloudImage != nil && cloudAudio != nil
    }

    var uiImage: UIImage? {
        guard let image = image else { return nil }
        return UIImage(contentsOfFile: image.url.path)
    }

    var syncAction: SyncAction {
        if let cloudImage = cloudImage, let cloudAudio = cloudAudio {
            if let image = image, let audio = audio {
                if image.exists && cloudImage.size == image.size && audio.exists && cloudAudio.size == audio.size {
                    return .None
                } else {
                    return .Download
                }
            } else {
                return .Download
            }
        } else {
            return .Delete
        }
    }
}

extension Song {
    init(title: String) {
        self.title = title
    }
}
