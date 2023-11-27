//
//  AppDelegate.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 7/2/17.
//  Copyright © 2017 Menalto. All rights reserved.
//

import AVKit
import UIKit
import EasyAnimation
import Amplitude_iOS
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UserDefaults.standard.registerDefaults()

        UIApplication.shared.isIdleTimerDisabled = true

        // Amplitude.instance()?.initializeApiKey("acf6c06b5191ae9e84ae07c47d02759e")
        EasyAnimation.enable()
        Stats().appLaunched()
        Manager.songs.loadLocal()
        Manager.movies.loadLocal()
        Manager.images.loadLocal()

        try! AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try! AVAudioSession.sharedInstance().setActive(true)

        return true
    }
}

extension AppDelegate {
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return GoogleDrive.instance.handle(url)
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GoogleDrive.instance.handle(url)
    }
}
