//
//  AppDelegate.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 7/2/17.
//  Copyright © 2017 Menalto. All rights reserved.
//

import UIKit
import EasyAnimation
import Amplitude_iOS

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UserDefaults.standard.registerDefaults()

        UIApplication.shared.isIdleTimerDisabled = true

        Amplitude.instance()?.initializeApiKey("acf6c06b5191ae9e84ae07c47d02759e")
        EasyAnimation.enable()
        Stats().appLaunched()
        return true
    }
}
