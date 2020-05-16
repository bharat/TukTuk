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
    func appLaunched() {
        Amplitude.instance()?.logEvent("AppLaunched")
    }

    func start(song: Song) {
        Amplitude.instance()?.logEvent("StartSong", withEventProperties: ["title": song.title])
    }

    func start(movie: Movie) {
        Amplitude.instance()?.logEvent("StartMovie", withEventProperties: ["title": movie.title])
    }

    func start(miniGame: MiniGame) {
        Amplitude.instance()?.logEvent("StartMiniGame", withEventProperties: ["title": miniGame.title])
    }

    func cue(movie: Movie) {
        Amplitude.instance()?.logEvent("CueMovie", withEventProperties: ["title": movie.title])
    }

    func cue(miniGame: MiniGame) {
        Amplitude.instance()?.logEvent("CueMiniGame", withEventProperties: ["title": miniGame.title])
    }
}
