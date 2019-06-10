//
//  AdminTabBarController.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/8/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation
import UIKit

class AdminTabBarController: UITabBarController {
    override func viewDidLoad() {
        if LocalStorage.instance.songs?.count ?? 0 == 0 {
            // Jump to the Sync tab
            selectedIndex = 1
        }
    }
}
