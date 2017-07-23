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

    var audioPlayer: AVAudioPlayer?
    var videoPlayer: AVPlayer?
    var songs: [Song] = []
    var surprises: [Surprise] = []
    var songPlayCount = 0
    var audioDurationSinceLastSurpriseShown: TimeInterval = 0
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

        for s in try! FileManager.default.contentsOfDirectory(
            atPath: Bundle.main.resourcePath! + "/Surprises") {
                surprises.append(Surprise(movie: Bundle.main.url(forAuxiliaryExecutable: "Surprises/\(s)")!))
        }

        hideSurpriseButton()
        hideVideo()
    }

    override func viewDidAppear(_ animated: Bool) {
        playAudio(Bundle.main.url(forAuxiliaryExecutable: "Meta/welcome.mp3")!)
    }

    @IBAction func buttonTapped(_ sender: UIButton) {
        switch(sender) {
        case surpriseButton:
            playVideo(surprises[Int(arc4random_uniform(UInt32(surprises.count)))].movie)
            hideSurpriseButton()

        case stopButton:
            stopAudio()
            stopVideo()
            hideVideo()

        default:
            ()
        }
    }

    @IBAction func surpriseTapped(_ sender: Any) {
        toggleMuteVideo()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        playAudio(songs[indexPath.row].music)
        songPlayCount += 1
        maybeShowSurprise()

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

    // MARK: Surprise

    func hideSurpriseButton() {
        surpriseButton.isHidden = true
    }

    func showSurpriseButton() {
        surpriseButton.isHidden = false
    }

    func maybeShowSurprise() {
        if audioDurationSinceLastSurpriseShown > 3600 {
            showSurpriseButton()
            audioDurationSinceLastSurpriseShown = 0
        }
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

    func stopAudio() {
        if let player = audioPlayer {
            audioDurationSinceLastSurpriseShown += player.currentTime
        }
        print("audio duration: \(audioDurationSinceLastSurpriseShown)")
        audioPlayer?.stop()
        audioPlayer = nil
    }
}

