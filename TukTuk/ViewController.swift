//
//  ViewController.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 7/2/17.
//  Copyright © 2017 Menalto. All rights reserved.
//

import UIKit
import AVFoundation
import SwiftGifOrigin

struct Song {
    var image: UIImage
    var music: URL
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var musicTable: UITableView!
    @IBOutlet weak var overlay: UIImageView!
    @IBOutlet weak var stopButton: UIButton!

    var audioPlayer: AVAudioPlayer?
    var videoPlayer: AVPlayer?
    var songs: [Song] = []
    weak var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        let catalogUrl = Bundle.main.url(forAuxiliaryExecutable: "Meta/catalog.txt")
        let catalog = try! String(contentsOf: catalogUrl!, encoding: .utf8).components(separatedBy: "\n")
        songs = []
        for i in 0..<catalog.count/2 {
            songs.append(Song(
                image: UIImage(named: "Songs/\(catalog[2*i])")!,
                music: Bundle.main.url(forAuxiliaryExecutable: "Songs/\(catalog[2*i+1])")!))
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        playAudio(Bundle.main.url(forAuxiliaryExecutable: "Meta/welcome.mp3")!)

        /*
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) {
            [weak self] _ in
                self?.showSurprise()
        }
         */
    }

    func showSurprise() {
        let url = Bundle.main.url(forAuxiliaryExecutable: "Meta/minions.mp4")
        videoPlayer = AVPlayer(url: url!)
        let videoPlayerLayer = AVPlayerLayer(player: videoPlayer)
        videoPlayerLayer.frame = overlay.bounds
        overlay.layer.addSublayer(videoPlayerLayer)
        videoPlayer?.play()
        videoPlayer?.isMuted = true

        let width: CGFloat = 240
        let height: CGFloat = 135
        let x = self.view.frame.width - width
        let y = self.stopButton.frame.origin.y - height - 8
        let duration = videoPlayer?.currentItem?.asset.duration.seconds

        overlay.layer.frame = CGRect(x: x, y: y, width: width, height: height)

        UIView.animate(withDuration: duration!, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.overlay.frame = CGRect(x: 0, y: y, width: width, height: height)
        })

        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.surpriseFinished), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: videoPlayer?.currentItem)
    }

    func surpriseFinished() {
        self.overlay.isHidden = true
    }

    @IBAction func surpriseTapped(_ sender: Any) {
        videoPlayer?.isMuted = !(videoPlayer?.isMuted)!
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        playAudio(songs[indexPath.row].music)

        tableView.beginUpdates()
        tableView.endUpdates()
    }

    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MusicCell")!

        cell.backgroundView = UIImageView(image: songs[indexPath.row].image)
        cell.backgroundView?.contentMode = .scaleAspectFill
        cell.selectedBackgroundView = UIImageView(image: songs[indexPath.row].image)
        cell.selectedBackgroundView?.contentMode = .scaleAspectFill

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == tableView.indexPathForSelectedRow?.row {
            return 300
        } else {
            return 150
        }
    }

    // MARK: General

    func playAudio(_ url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            guard let player = audioPlayer else {
                return
            }

            player.prepareToPlay()
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }

    @IBAction func stopAudio(_ sender: Any) {
        if let player = audioPlayer {
            player.stop()
        }
    }
}

