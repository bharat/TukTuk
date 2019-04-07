//
//  URL.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 2/24/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation

extension URL {
    var lowerCaseString: String {
        get {
            return absoluteString.lowercased()
        }
    }
}
