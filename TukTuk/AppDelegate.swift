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
    var window: UIWindow? = DebugWindow()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        let defaultValue = ["surpriseCountdown": 1800]
        UserDefaults.standard.register(defaults: defaultValue)

        UIApplication.shared.isIdleTimerDisabled = true

        EasyAnimation.enable()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }
}

class DebugWindow: UIWindow {
//    override func sendEvent(_ event: UIEvent) {
//        print("Event: \(event)")
//        if let touch = event.allTouches?.first {
//            let point = touch.location(in: self)
//            if let view = hitTest(point, with: event) {
//                print("Touch: \(view)")
//            }
//        }
//
//        super.sendEvent(event)
//    }
}
