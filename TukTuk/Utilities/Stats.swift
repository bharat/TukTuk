//
//  Stats.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 4/3/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation
import Amplitude_iOS

class Stats {
    func log(_ eventType: String, titled: Titled? = nil) {
        var props = [
            "child": UserDefaults.standard.child?.name ?? ""
        ]

        if let titled = titled {
            props["title"] = titled.title
        }
        Amplitude.instance()?.logEvent(eventType, withEventProperties: props)
    }

    func appLaunched() {
        log("AppLaunched")
    }

    func synchronize() {
        log("Synchronize")
    }

    func start(song: Song) {
        log("StartSong", titled: song)
    }

    func complete(song: Song) {
        log("CompleteSong", titled: song)
    }

    func stop(song: Song) {
        log("StopSong", titled: song)
    }

    func start(movie: Movie) {
        log("StartMovie", titled: movie)
    }

    func start(miniGame: MiniGame) {
        log("StartMiniGame", titled: miniGame)
    }

    func cue(movie: Movie) {
        log("CueMovie", titled: movie)
    }

    func cue(miniGame: MiniGame) {
        log("CueMiniGame", titled: miniGame)
    }
}
