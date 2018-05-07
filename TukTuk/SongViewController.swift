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
    var audio = Audio()
    var video = Video()

    var surpriseTimer: Timer?
    var surpriseCountdown: TimeInterval = 0 {
        didSet {
            surpriseTimerLabel.text = "\(Int(surpriseCountdown))"
        }
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        hideSurpriseButton()
        showWelcomeOverlay()

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
            audio.stop()
            if let surprise = Catalog.default.surprises.random {
                video.play(surprise.movie, from: self)
            }
            disableStopButton()
            stopSurpriseTimer()
            hideSurpriseButton()

        case stopButton:
            audio.stop()
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

    @objc func handleWelcomeLongPress(gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            show(welcomeAnimationChooser(), sender: self)
        }
    }

    @objc func handleSurpriseLongPress(gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            show(surpriseChooser(), sender: self)
        }
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        switch(previewingContext.sourceView) {
        case welcomeOverlay:
            show(welcomeAnimationChooser(), sender: self)
            break
        case stopButton:
            show(surpriseChooser(), sender: self)
        default:
            break
        }
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        switch(previewingContext.sourceView) {
        case welcomeOverlay:
            return welcomeAnimationChooser()
        case stopButton:
            return surpriseChooser()
        default:
            return nil
        }
    }

    func welcomeAnimationChooser() -> PreviewingTableViewController {
        let previewTVC = storyboard?.instantiateViewController(withIdentifier: "PreviewTableVC") as! PreviewingTableViewController
        previewTVC.tableTitle = "Choose the welcome animation"
        previewTVC.rowTitles = Animations.all.map { $0.title }
        previewTVC.completion = { index in
            self.presetWelcome = Animations.all[index]
        }
        return previewTVC
    }

    func surpriseChooser() -> PreviewingTableViewController {
        let previewTVC = storyboard?.instantiateViewController(withIdentifier: "PreviewTableVC") as! PreviewingTableViewController
        let surprises = Catalog.default.surprises

        previewTVC.tableTitle = "Which video should we play?"
        previewTVC.rowTitles = surprises.map { $0.title }
        previewTVC.completion = { index in
            self.audio.stop()
            self.video.play(surprises[index].movie, from: self)
        }
        return previewTVC
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
        audio.play(Catalog.default.welcomeSong)

        animation.animate(view: welcomeImageView) {
            self.welcomeOverlay.removeFromSuperview()
        }
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if video.isPlaying == false {
            audio.play(Catalog.default.songs[indexPath.row].music)
            enableStopButton()
            startSurpriseTimer()

            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }

    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Catalog.default.songs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MusicCell")!
        let songs = Catalog.default.songs

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
        if audio.isPlaying {
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

}

