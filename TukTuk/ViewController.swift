//
//  ViewController.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 7/2/17.
//  Copyright © 2017 Menalto. All rights reserved.
//

import UIKit
import AVFoundation

struct Song {
    var image: UIImage
    var music: URL
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var musicTable: UITableView!
    var player: AVAudioPlayer?
    var songs: [Song] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        let catalogUrl = Bundle.main.url(forResource: "catalog", withExtension: "txt", subdirectory: "Music")
        let catalog = try! String(contentsOf: catalogUrl!, encoding: .utf8).components(separatedBy: "\n")
        songs = []
        for i in 0..<catalog.count/2 {
            songs.append(Song(
                image: UIImage(named: "Music/\(catalog[2*i])")!,
                music: Bundle.main.url(forAuxiliaryExecutable: "Music/\(catalog[2*i+1])")!))
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        playAudio(Bundle.main.url(forAuxiliaryExecutable: "Music/welcome.mp3")!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        playAudio(songs[indexPath.row].music)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MusicCell")!

        cell.backgroundView = UIImageView(image: songs[indexPath.row].image)
        cell.backgroundView?.contentMode = .scaleAspectFill

        return cell
    }

    // MARK: General

    func playAudio(_ url: URL) {
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

    @IBAction func stopAudio(_ sender: Any) {
        if let player = player {
            player.stop()
        }
    }
}

