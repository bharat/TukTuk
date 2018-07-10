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

        let defaultValue = ["videoCountdown": TimeInterval.VideoInterval]
        UserDefaults.standard.register(defaults: defaultValue)

        UIApplication.shared.isIdleTimerDisabled = true

        EasyAnimation.enable()
        return true
    }
}
