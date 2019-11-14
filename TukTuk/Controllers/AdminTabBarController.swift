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
        if Manager.songs.localEmpty {
            // Jump to the Sync tab
            selectedIndex = 1
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let delay = Double(Array(10...30).randomElement()!)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if self.view.window != nil {
                Delight.showBunny(on: self.view)
            }
        }
    }
}
