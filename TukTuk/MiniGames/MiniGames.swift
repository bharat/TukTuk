//
//  MiniGames.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/11/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit

protocol MiniGame: Preloadable {
    var title: String { get }
    var uivc: UIViewController { get }
}

class MiniGames {
    static var all: [MiniGame] = [
        Thor(),
        AvengersAssemble(),
        JusticeLeague()
    ]

    static func preloadableAssets() -> [URL] {
        return all.flatMap { $0.preloadableAssets() }
    }
}
