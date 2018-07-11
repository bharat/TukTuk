//
//  AppDelegate.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 7/2/17.
//  Copyright © 2017 Menalto. All rights reserved.
//

import UIKit
import EasyAnimation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        UserDefaults.standard.register(defaults: [
            String.videoCountdownKey: TimeInterval.VideoInterval
        ])

        UIApplication.shared.isIdleTimerDisabled = true

        EasyAnimation.enable()
        return true
    }
}
