//
//  Preloader.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 2/4/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation

protocol Preloadable {
    func preloadableAssets() -> [URL]
}
