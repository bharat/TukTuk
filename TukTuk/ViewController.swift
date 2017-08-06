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

struct Surprise {
    var movie: URL
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var musicTable: UITableView!
    @IBOutlet weak var overlay: UIImageView!
    
    @IBOutlet weak var buttons: UIStackView!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var surpriseButton: UIButton!
    @IBOutlet weak var surpriseTimerLabel: UILabel!

    var audioPlayer: AVAudioPlayer?
    var videoPlayer: AVPlayer?
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

        let catalogUrl = Bundle.main.url(forAuxiliaryExecutable: "Meta/catalog.txt")
        let catalog = try! String(contentsOf: catalogUrl!, encoding: .utf8).components(separatedBy: "\n")
        songs = []
        for i in 0..<catalog.count/2 {
            songs.append(Song(
                image: UIImage(named: "Songs/\(catalog[2*i])")!,
                music: Bundle.main.url(forAuxiliaryExecutable: "Songs/\(catalog[2*i+1])")!))
        }

        for s in try! FileManager.default.contentsOfDirectory(
            atPath: Bundle.main.resourcePath! + "/Surprises") {
                surprises.append(Surprise(movie: Bundle.main.url(forAuxiliaryExecutable: "Surprises/\(s)")!))
        }


        hideSurpriseButton()
        hideVideo()
    }

    override func viewDidAppear(_ animated: Bool) {
        loadSurpriseCountdown()

        Timer.scheduledTimer(timeInterval: 8, target: self, selector: (#selector(ViewController.playWelcomeAudio)), userInfo: nil, repeats: false)
    }

    func playWelcomeAudio() {
        playAudio(Bundle.main.url(forAuxiliaryExecutable: "Meta/welcome.mp3")!)
    }

    @IBAction func buttonTapped(_ sender: UIButton) {
        switch(sender) {
        case surpriseButton:
            playVideo(surprises[Int(arc4random_uniform(UInt32(surprises.count)))].movie)
            stopSurpriseTimer()
            hideSurpriseButton()

        case stopButton:
            stopAudio()
            stopVideo()
            hideVideo()
            stopSurpriseTimer()
            saveSurpriseCountdown()

        default:
            ()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
    @IBAction func surpriseTapped(_ sender: Any) {
        toggleMuteVideo()
    }

    func loadSurpriseCountdown() {
        surpriseCountdown = UserDefaults.standard.double(forKey: "surpriseCountdown")
        print("surprise countdown \(surpriseCountdown)")
    }

    func hideSurpriseButton() {
        UIView.animate(withDuration: 1) {
            self.surpriseTimerLabel.isHidden = false
            self.surpriseButton.isHidden = true
        }
    }

    func showSurpriseButton() {
        UIView.animate(withDuration: 1){
            self.surpriseButton.isHidden = false
            self.surpriseTimerLabel.isHidden = true
        }
    }

    func startSurpriseTimer() {
        surpriseTimer?.invalidate()
        surpriseTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(ViewController.updateSurpriseCountdown)), userInfo: nil, repeats: true)
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

    func stopSurpriseTimer() {
        surpriseTimer?.invalidate()
        surpriseTimer = nil
    }

    func saveSurpriseCountdown() {
        print("saving surprise countdown \(surpriseCountdown)")
        UserDefaults.standard.setValue(surpriseCountdown, forKey: "surpriseCountdown")
        UserDefaults.standard.synchronize()
    }

    // MARK: Audio & Video

    func playAudio(_ url: URL) {
        stopAudio()
        stopVideo()
        hideVideo()

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

    func playVideo(_ url: URL) {
        stopAudio()
        stopVideo()

        // Load a new one
        videoPlayer = AVPlayer(url: url)
        let videoPlayerLayer = AVPlayerLayer(player: videoPlayer)
        videoPlayerLayer.frame = overlay.bounds
        overlay.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        overlay.layer.addSublayer(videoPlayerLayer)
        videoPlayer?.play()
        videoPlayer?.isMuted = false
        overlay.isHidden = false

        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.hideVideo), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: videoPlayer?.currentItem)
    }

    func toggleMuteVideo() {
        videoPlayer?.isMuted = !(videoPlayer?.isMuted)!
    }

    func stopVideo() {
        videoPlayer?.pause()
        videoPlayer = nil
    }

    func hideVideo() {
        overlay.isHidden = true
    }

    func videoIsPlaying() -> Bool {
        return videoPlayer != nil
    }

    func audioIsPlaying() -> Bool {
        return audioPlayer?.isPlaying ?? false
    }

    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}

