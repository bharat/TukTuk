//
//  UIImage.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/22/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    // From: https://github.com/SwifterSwift/SwifterSwift/blob/master/Sources/Extensions/UIKit/UIImageExtensions.swift
    // Consider using SwifterSwift pod
    func crop(to rect: CGRect) -> UIImage {
        guard rect.size.height < size.height && rect.size.width < size.width else { return self }
        guard let image: CGImage = cgImage?.cropping(to: rect) else { return self }
        return UIImage(cgImage: image)
    }
}
