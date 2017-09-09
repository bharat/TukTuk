//
//  ViewController.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 7/2/17.
//  Copyright © 2017 Menalto. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import SwiftGifOrigin

struct Song {
    var image: UIImage
    var music: URL
}

struct Surprise {
    var movie: URL
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var musicTable: UITableView!
    @IBOutlet weak var buttons: UIStackView!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var surpriseButton: UIButton!
    @IBOutlet weak var surpriseTimerLabel: UILabel!

    var audioPlayer: AVAudioPlayer = AVAudioPlayer()
    var videoPlayer: AVPlayer = AVPlayer()
    var videoPlayerController: AVPlayerViewController = AVPlayerViewController()

    var songs: [Song] = []
    var surprises: [Surprise] = []
    var surpriseTimer: Timer?
    var surpriseCountdown: TimeInterval = 0 {
        didSet {
            surpriseTimerLabel.text = "\(Int(surpriseCountdown))"
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Load the music catalog
        let catalogUrl = Bundle.main.url(forAuxiliaryExecutable: "Meta/catalog.txt")
        let catalog = try! String(contentsOf: catalogUrl!, encoding: .utf8).components(separatedBy: "\n")
        songs = []
        for i in 0..<catalog.count/2 {
            songs.append(Song(
                image: UIImage(named: "Songs/\(catalog[2*i])")!,
                music: Bundle.main.url(forAuxiliaryExecutable: "Songs/\(catalog[2*i+1])")!))
        }

        // Load the "surprise" video catalog
        for s in try! FileManager.default.contentsOfDirectory(
            atPath: Bundle.main.resourcePath! + "/Surprises") {
                surprises.append(Surprise(movie: Bundle.main.url(forAuxiliaryExecutable: "Surprises/\(s)")!))
        }

        hideSurpriseButton()
        videoPlayerController.showsPlaybackControls = false
    }

    override func viewDidAppear(_ animated: Bool) {
        loadSurpriseCountdown()

        playWelcomeAudio()
    }

    @IBAction func buttonTapped(_ sender: UIButton) {
        switch(sender) {
        case surpriseButton:
            stopAudio()
            playVideo(surprises[Int(arc4random_uniform(UInt32(surprises.count)))].movie)
            stopSurpriseTimer()
            hideSurpriseButton()

        case stopButton:
            stopAudio()
            stopSurpriseTimer()
            saveSurpriseCountdown()

        default:
            ()
        }
    }


    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if videoIsPlaying() == false {
            playAudio(songs[indexPath.row].music)
            startSurpriseTimer()

            tableView.beginUpdates()
            tableView.endUpdates()
        }
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

    // MARK: Surprise

    func showSurpriseButton() {
        UIView.animate(withDuration: 1){
            self.surpriseButton.isHidden = false
            self.surpriseTimerLabel.isHidden = true
        }
    }

    func hideSurpriseButton() {
        UIView.animate(withDuration: 1) {
            self.surpriseTimerLabel.isHidden = false
            self.surpriseButton.isHidden = true
        }
    }

    func startSurpriseTimer() {
        surpriseTimer?.invalidate()
        surpriseTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(ViewController.updateSurpriseCountdown)), userInfo: nil, repeats: true)
    }

    func stopSurpriseTimer() {
        surpriseTimer?.invalidate()
        surpriseTimer = nil
    }

    func loadSurpriseCountdown() {
        surpriseCountdown = UserDefaults.standard.double(forKey: "surpriseCountdown")
        print("surprise countdown \(surpriseCountdown)")
    }

    func updateSurpriseCountdown() {
        if audioIsPlaying() {
            surpriseCountdown -= 1

            if surpriseCountdown <= 0 {
                showSurpriseButton()
                surpriseCountdown = 3600
            }
        }
    }

    func saveSurpriseCountdown() {
        print("saving surprise countdown \(surpriseCountdown)")
        UserDefaults.standard.setValue(surpriseCountdown, forKey: "surpriseCountdown")
        UserDefaults.standard.synchronize()
    }

    // MARK: Audio

    func playWelcomeAudio() {
        playAudio(Bundle.main.url(forAuxiliaryExecutable: "Meta/welcome.mp3")!,
                  after: 8)
    }

    func playAudio(_ url: URL, after delay: TimeInterval = 0) {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.prepareToPlay()
            audioPlayer.play(atTime: audioPlayer.deviceCurrentTime + delay)
        } catch let error {
            print(error.localizedDescription)
        }
    }

    func audioIsPlaying() -> Bool {
        return audioPlayer.isPlaying
    }

    func stopAudio() {
        audioPlayer.stop()
    }

    // MARK: Video

    func playVideo(_ url: URL) {
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        videoPlayer = AVPlayer(playerItem: playerItem)
        videoPlayer.play()

        videoPlayerController.player = videoPlayer
        present(videoPlayerController, animated: true, completion: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.hideVideo), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: videoPlayer.currentItem)
    }

    func stopVideo() {
        videoPlayer.pause()
    }

    func hideVideo() {
        videoPlayerController.dismiss(animated: true, completion: nil)
    }

    func videoIsPlaying() -> Bool {
        if #available(iOS 10.0, *) {
            return videoPlayer.timeControlStatus == .playing
        } else {
            // Fallback on earlier versions
            return videoPlayer.rate == 0.0
        }
    }
}

