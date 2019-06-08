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
    var active: LocalSong?

    func appLaunched() {
        Amplitude.instance()?.logEvent("AppLaunched")
    }

    func start(song: LocalSong) {
        Amplitude.instance()?.logEvent("StartSong", withEventProperties: ["title": song.title])
        active = song
    }

    func start(movie: LocalMovie) {
        Amplitude.instance()?.logEvent("StartMovie", withEventProperties: ["title": movie.title])
    }

    func start(miniGame: MiniGame) {
        Amplitude.instance()?.logEvent("StartMiniGame", withEventProperties: ["title": miniGame.title])
    }

    func cue(movie: LocalMovie) {
        Amplitude.instance()?.logEvent("CueMovie", withEventProperties: ["title": movie.title])
    }

    func cue(miniGame: MiniGame) {
        Amplitude.instance()?.logEvent("CueMiniGame", withEventProperties: ["title": miniGame.title])
    }

    func stop() {
        if let active = active {
            Amplitude.instance()?.logEvent("StopSong", withEventProperties: ["title": active.title])
        }
        active = nil
    }

    func complete() {
        if let active = active {
            Amplitude.instance()?.logEvent("CompleteSong", withEventProperties: ["title": active.title])
        }
        active = nil
    }
}
