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
    var bunny = BunnyDelight()
        
    override func viewWillAppear(_ animated: Bool) {
        var desiredIndex: Int?

        if UserDefaults.standard.child == nil {
            desiredIndex = 2
        } else if Manager.songs.localEmpty {
            desiredIndex = 1
        }

        if let desiredIndex = desiredIndex {
            // Jump to the specific tab. Do it async with a delay otherwise the tab's
            // viewDidAppear() doesn't get called.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.selectedIndex = desiredIndex
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let delay = Double(Array(10...30).randomElement()!)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if self.view.window != nil {
                self.bunny.show(on: self.view)
            }
        }
    }
}
