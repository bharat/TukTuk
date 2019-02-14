//
//  String.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 2/14/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation

extension String {
    func camelCaseToWords() -> String {
        return unicodeScalars.reduce("") {
            if CharacterSet.uppercaseLetters.contains($1) {
                return ($0 + ($0.count > 0 ? " " : "") + String($1))
            } else {
                return $0 + String($1)
            }
        }
    }
}
