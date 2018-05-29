//
//  Array.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/29/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {
    func allTheSame() -> Bool {
        return filter { $0 == self[0] }.count == self.count
    }
}
