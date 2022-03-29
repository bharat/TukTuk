//
//  Image.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 3/27/22.
//  Copyright © 2022 Menalto. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

struct Image: Manageable {
    var title: String
    var image: LocalFileProtocol?
    var cloudImage: CloudFileProtocol?

    var hasLocal: Bool {
        return image?.exists ?? false
    }

    var hasWellFormedCloud: Bool {
        return cloudImage != nil
    }
    
    var malformedCloudDiagnosis: String? {
        if cloudImage == nil {
            return "Missing image for \"\(title)\""
        }
        return nil
    }

    var uiImage: UIImage? {
        guard let image = image else { return nil }
        return UIImage(contentsOfFile: image.url.path)
    }
    
    var skTexture: SKTexture? {
        guard let uiImage = uiImage else { return nil }
        return SKTexture(image: uiImage)
    }

    var syncAction: SyncAction {
        // A well-formed cloud song has an image and either an audio track or a video clip
        guard let cloudImage = cloudImage else {
            return .Delete
        }
                        
        if cloudImage.size != image?.size {
            return .Download
        }
        
        return .None
    }

    mutating func deleteLocal() {
        image?.delete()
        image = nil
    }
}
