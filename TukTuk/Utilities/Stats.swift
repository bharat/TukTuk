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
        Amplitude.instance()?.logEvent("AppLaunched", withEventProperties: ["child": UserDefaults.standard.child?.name ?? ""])
    }

    func props(title: String) -> [String:String] {
        return ["title": title, "child": UserDefaults.standard.child?.name ?? ""]
    }

    func start(song: Song) {
        Amplitude.instance()?.logEvent("StartSong", withEventProperties: props(title: song.title))
    }

    func complete(song: Song) {
        Amplitude.instance()?.logEvent("CompleteSong", withEventProperties: props(title: song.title))
    }

    func stop(song: Song) {
        Amplitude.instance()?.logEvent("StopSong", withEventProperties: props(title: song.title))
    }

    func start(movie: Movie) {
        Amplitude.instance()?.logEvent("StartMovie", withEventProperties: props(title: movie.title))
    }

    func start(miniGame: MiniGame) {
        Amplitude.instance()?.logEvent("StartMiniGame", withEventProperties: props(title: miniGame.title))
    }

    func cue(movie: Movie) {
        Amplitude.instance()?.logEvent("CueMovie", withEventProperties: props(title: movie.title))
    }

    func cue(miniGame: MiniGame) {
        Amplitude.instance()?.logEvent("CueMiniGame", withEventProperties: props(title: miniGame.title))
    }
}
