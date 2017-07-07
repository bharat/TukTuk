//
//  ViewController.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 7/2/17.
//  Copyright © 2017 Menalto. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    var player: AVAudioPlayer?

    var songs: [String] = [
        "OldMacDonaldHadAFarm",
        "TwinkleTwinkleLittleStar",
        "RowRowRowYourBoat",
        "GongXiFaCai",
        "XiaoXingXing"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(_ animated: Bool) {
        playAudio("welcome")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func playAudio(_ fileName: String) {
        if let url = Bundle.main.url(forResource: fileName, withExtension: "mp3", subdirectory: "Music") {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                try AVAudioSession.sharedInstance().setActive(true)

                player = try AVAudioPlayer(contentsOf: url)
                guard let player = player else { return }

                player.prepareToPlay()
                player.play()
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }

    @IBAction func stop(_ sender: Any) {
        if let player = player {
            player.stop()
        }
    }

    @IBAction func musicButton(_ sender: UIButton) {
        playAudio(songs[sender.tag])
    }
}

