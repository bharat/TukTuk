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

class SongViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIViewControllerPreviewingDelegate {
    @IBOutlet weak var musicTable: UITableView!
    @IBOutlet weak var buttons: UIStackView!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var surpriseButton: UIButton!
    @IBOutlet weak var surpriseTimerLabel: UILabel!

    var welcomeOverlay = UIView()
    var welcomeImageView = UIImageView()
    var presetWelcome: Animation?
    var audioPlayer: AVAudioPlayer?
    var videoPlayer = AVPlayer()
    var videoPlayerController = AVPlayerViewController()

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

        // 3DTouch or a long press on the stop button will bring up an interface where you can
        // start a surprise video
        registerForPreviewing(with: self, sourceView: stopButton)
        let long = UILongPressGestureRecognizer(target: self, action: #selector(handleSurpriseLongPress(gesture:)))
        long.minimumPressDuration = 5.0
        stopButton.addGestureRecognizer(long)
    }

    override func viewDidAppear(_ animated: Bool) {
        loadSurpriseCountdown()
    }

    @IBAction func buttonTapped(_ sender: UIButton) {
        switch(sender) {
        case surpriseButton:
            stopAudio()
            if let surprise = surprises.random {
                playVideo(surprise.movie)
            }
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

    // MARK: Secret parent interfaces

    func showWelcomeAnimationChooser() {
        let previewTVC = storyboard?.instantiateViewController(withIdentifier: "PreviewTableVC") as! PreviewingTableViewController
        previewTVC.titles = Animations.all.map { $0.title }
        previewTVC.completion = { index in
            self.presetWelcome = Animations.all[index]
        }
        show(previewTVC, sender: self)
    }

    func showSurpriseChooser() {
        let previewTVC = storyboard?.instantiateViewController(withIdentifier: "PreviewTableVC") as! PreviewingTableViewController
        previewTVC.titles = self.surprises.map { $0.title }
        previewTVC.completion = { index in
            self.stopAudio()
            self.playVideo(self.surprises[index].movie)
        }
        show(previewTVC, sender: self)
    }

    @objc func handleWelcomeLongPress(gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            showWelcomeAnimationChooser()
        }
    }

    @objc func handleSurpriseLongPress(gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            showSurpriseChooser()
        }
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        switch(previewingContext.sourceView) {
        case welcomeOverlay:
            showWelcomeAnimationChooser()
            break
        case stopButton:
            showSurpriseChooser()
        default:
            break
        }
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        let previewTVC = storyboard?.instantiateViewController(withIdentifier: "PreviewTableVC") as! PreviewingTableViewController

        switch(previewingContext.sourceView) {
        case welcomeOverlay:
            previewTVC.titles = Animations.all.map { $0.title }
            return previewTVC
        case stopButton:
            previewTVC.titles = self.surprises.map { $0.title }
            return previewTVC
        default:
            return nil
        }
    }

    // MARK: Welcome

    func showWelcomeOverlay() {
        welcomeImageView = UIImageView(frame: self.view.frame)
        welcomeImageView.contentMode = .scaleAspectFill
        welcomeImageView.clipsToBounds = true
        welcomeImageView.image = #imageLiteral(resourceName: "Welcome")
        welcomeImageView.layer.borderWidth = 8
        welcomeImageView.layer.borderColor = UIColor.black.cgColor
        welcomeImageView.layer.cornerRadius = 0

        welcomeOverlay = UIView(frame: self.view.frame)
        welcomeOverlay.addSubview(welcomeImageView)
        self.view.addSubview(welcomeOverlay)

        let tap = UITapGestureRecognizer(target: self, action: #selector(SongViewController.handleWelcomeTap(sender:)))
        welcomeOverlay.addGestureRecognizer(tap)

        // 3DTouch or a long press on the welcome image will bring up an interface where you can
        // choose which animation will play
        registerForPreviewing(with: self, sourceView: welcomeOverlay)
        let long = UILongPressGestureRecognizer(target: self, action: #selector(handleWelcomeLongPress(gesture:)))
        long.minimumPressDuration = 5.0
        welcomeOverlay.addGestureRecognizer(long)
    }

    @objc func handleWelcomeTap(sender: UITapGestureRecognizer) {
        self.welcomeOverlay.removeGestureRecognizer(sender)

        // Run a random welcome animation, or a preset if specified
        welcome(animation: presetWelcome ?? Animations.random)
    }

    func welcome(animation: Animation) {
        playWelcomeAudio()

        animation.animate(view: welcomeImageView) {
            self.welcomeOverlay.removeFromSuperview()
        }
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
                surprises.append(Surprise(title: s, movie: Bundle.main.url(forAuxiliaryExecutable: "Surprises/\(s)")!))
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
        surpriseTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(SongViewController.updateSurpriseCountdown)), userInfo: nil, repeats: true)
    }

    func stopSurpriseTimer() {
        surpriseTimer?.invalidate()
        surpriseTimer = nil
    }

    func loadSurpriseCountdown() {
        surpriseCountdown = UserDefaults.standard.double(forKey: "surpriseCountdown")
        print("surprise countdown \(surpriseCountdown)")
    }

    @objc func updateSurpriseCountdown() {
        if audioIsPlaying() {
            surpriseCountdown -= 1

            if surpriseCountdown <= 0 {
                showSurpriseButton()
                surpriseCountdown = 1800
            }
        }
    }

    func saveSurpriseCountdown() {
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

        NotificationCenter.default.addObserver(self, selector: #selector(SongViewController.hideVideo), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: videoPlayer.currentItem)
    }

    func stopVideo() {
        videoPlayer.pause()
    }

    @objc func hideVideo() {
        videoPlayerController.dismiss(animated: true, completion: nil)
    }

    func videoIsPlaying() -> Bool {
        return videoPlayerController.isPlaying
    }
}

