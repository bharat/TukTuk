//
//  Movie.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/12/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation

struct Movie: Manageable, Titled {
    var title: String
    var video: LocalFile?
    var cloudVideo: CloudFile?

    var hasLocal: Bool {
        return video != nil && video!.exists
    }

    var hasCloud: Bool {
        return cloudVideo != nil
    }

    var syncAction: SyncAction {
        if let cloudVideo = cloudVideo {
            if let video = video {
                if video.exists && cloudVideo.size == video.size {
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

    mutating func deleteLocal() {
        video?.delete()
        video = nil
    }
}

extension Movie {
    init(title: String) {
        self.title = title
    }
}
