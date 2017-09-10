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

    var firstTapOverlay: UIView?
    var welcomeImageView: UIImageView?
    var audioPlayer: AVAudioPlayer?
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

        loadCatalogs()
        hideSurpriseButton()
        showWelcomeOverlay()
        videoPlayerController.showsPlaybackControls = false
    }

    override func viewDidAppear(_ animated: Bool) {
        loadSurpriseCountdown()
    }


    @IBAction func buttonTapped(_ sender: UIButton) {
        switch(sender) {
        case surpriseButton:
            stopAudio()
            playVideo(surprises[Int(arc4random_uniform(UInt32(surprises.count)))].movie)
            disableStopButton()
            stopSurpriseTimer()
            hideSurpriseButton()

        case stopButton:
            stopAudio()
            disableStopButton()
            stopSurpriseTimer()
            saveSurpriseCountdown()

        default:
            ()
        }
    }

    func enableStopButton() {
        stopButton.isEnabled = true
    }

    func disableStopButton() {
        stopButton.isEnabled = false
    }

    // MARK: Welcome

    func showWelcomeOverlay() {
        welcomeImageView = UIImageView(frame: self.view.frame)
        welcomeImageView?.contentMode = .scaleAspectFill
        welcomeImageView?.clipsToBounds = true
        welcomeImageView?.image = #imageLiteral(resourceName: "Welcome")
        welcomeImageView?.layer.borderWidth = 8
        welcomeImageView?.layer.borderColor = UIColor.black.cgColor
        welcomeImageView?.layer.cornerRadius = 0

        firstTapOverlay = UIView(frame: self.view.frame)
        firstTapOverlay?.addSubview(welcomeImageView!)
        self.view.addSubview(firstTapOverlay!)

        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleWelcomeTap(sender:)))
        firstTapOverlay?.addGestureRecognizer(tap)
    }

    func handleWelcomeTap(sender: UITapGestureRecognizer) {
        self.firstTapOverlay?.removeGestureRecognizer(sender)
        welcomeTheUser()
    }

    func welcomeTheUser() {
        playWelcomeAudio()

        guard let overlay = self.firstTapOverlay else {
            return
        }

        // Animate away the welcome image. Shrink it down to 40% of its size in the
        // center of the screen, then do a "hinge" animation where the top right corner
        // releases and it falls down around the top left corner, then the whole image
        // falls off the bottom of the page.
        let easeInOut = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        let easeLinear = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                self.firstTapOverlay?.removeFromSuperview()
            }

            // Move the anchor point to the top left, so that the rotation effect looks like 
            // it's falling down on the right side. This will move the overlay, so make sure
            // that we recenter it.
            overlay.layer.anchorPoint = CGPoint(x: 0, y: 0)
            overlay.center = CGPoint(x: overlay.center.x * 0.6, y: overlay.center.y * 0.6)

            let second = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            second.fillMode = kCAFillModeForwards
            second.isRemovedOnCompletion = false
            second.beginTime = 0.1
            second.duration = 3.5

            let t = Float.pi / 7
            let k = Float.pi / 9
            second.values = [0.0] +
                [2.56, -1.28, 0.64, -0.32, 0.16, -0.08, 0.04, -0.02, 0.01].map { t + $0 * k } +
                [t]
            second.keyTimes = (0...10).map { (Double($0) * 0.1) as NSNumber }
            second.timingFunctions = [CAMediaTimingFunction](repeating: easeInOut, count: 10)

            let third = CAKeyframeAnimation(keyPath: "position.y")
            third.fillMode = kCAFillModeForwards
            third.isRemovedOnCompletion = false
            third.beginTime = second.beginTime + second.duration
            third.duration = 1.0
            third.values = [overlay.frame.origin.y, self.view.frame.height * 2]
            third.keyTimes = [0.0, 1.0]
            third.timingFunctions = [easeLinear]

            let group = CAAnimationGroup()
            group.duration = third.beginTime + third.duration
            group.fillMode = kCAFillModeForwards
            group.isRemovedOnCompletion = false
            group.animations = [second, third]
            self.firstTapOverlay?.layer.add(group, forKey:nil)
            CATransaction.commit()
        }

        let first = CAKeyframeAnimation(keyPath: "transform.scale")
        first.fillMode = kCAFillModeForwards
        first.isRemovedOnCompletion = false
        first.beginTime = 0.0
        first.duration = 1.0
        first.values =   [1.0, 0.35, 0.425, 0.3875, 0.40625, 0.3969, 0.4]
        first.keyTimes = [0.0, 0.5,  0.6,   0.7,    0.8,     0.9,    1.0]
        first.timingFunctions = [easeInOut, easeInOut, easeInOut, easeInOut, easeInOut]
        overlay.layer.add(first, forKey: nil)
        CATransaction.commit()
    }

    // MARK: Catalogs

    func loadCatalogs() {
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
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if videoIsPlaying() == false {
            playAudio(songs[indexPath.row].music)
            enableStopButton()
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
        playAudio(Bundle.main.url(forAuxiliaryExecutable: "Meta/welcome.mp3")!)
    }

    func playAudio(_ url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)

            let old = audioPlayer
            audioPlayer = try AVAudioPlayer(contentsOf: url)

            if let new = audioPlayer {
                new.play()

                if let old = old {
                    new.volume = 0
                    crossfadeAudio(old: old, new: new)
                }
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }

    func crossfadeAudio(old: AVAudioPlayer, new: AVAudioPlayer) {
        if new.volume < 1.0 {
            old.volume -= 0.1
            new.volume += 0.1

            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
                self.crossfadeAudio(old: old, new: new)
            }
        }
    }

    func audioIsPlaying() -> Bool {
        return audioPlayer?.isPlaying ?? false
    }

    func stopAudio() {
        audioPlayer?.stop()
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
            return videoPlayer.rate != 0.0
        }
    }
}

