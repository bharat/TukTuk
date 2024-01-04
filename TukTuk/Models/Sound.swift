//
//  Sound.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 10/5/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation

struct Sound {
    var url: URL

    func play(volume: Float = 1.0, done: @escaping ()->()={}) {
        SoundPlayer.instance.play(self, volume: volume, whenComplete: done)
    }
}
