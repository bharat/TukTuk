//
//  MiniGames.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/11/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit

protocol MiniGame: HasPreloadableAssets {
    var title: String { get }
    var uivc: UIViewController { get }

    init()
}

class MiniGames: Preloadable {
    static var all: [MiniGame] = [
        Thor(),
        AvengersAssemble(),
        JusticeLeague(),
        CaptainAmerica()
    ]

    static func preload() {
        all.forEach { _ = $0.preloadableAssets() }
    }
}
