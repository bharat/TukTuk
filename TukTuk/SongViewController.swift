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
            Audio.instance.stop()
            if let surprise = Catalog.instance.surprises.random {
                Video.instance.play(surprise.video, from: self)
            }
            disableStopButton()
            stopSurpriseTimer()
            hideSurpriseButton()

        case stopButton:
            Audio.instance.stop()
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

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if Video.instance.isPlaying == false {
            Audio.instance.play(Catalog.instance.songs[indexPath.row].music)
            enableStopButton()
            startSurpriseTimer()

            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }

    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Catalog.instance.songs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MusicCell")!
        let songs = Catalog.instance.songs

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
        if Audio.instance.isPlaying {
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
    @objc func handleSurpriseLongPress(gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            show(surpriseChooser(), sender: self)
        }
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        switch(previewingContext.sourceView) {
        case stopButton:
            show(surpriseChooser(), sender: self)
        default:
            break
        }
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        switch(previewingContext.sourceView) {
        case stopButton:
            return surpriseChooser()
        default:
            return nil
        }
    }

    func surpriseChooser() -> PreviewingTableViewController {
        let previewTVC = storyboard?.instantiateViewController(withIdentifier: "PreviewTableVC") as! PreviewingTableViewController
        let surprises = Catalog.instance.surprises

        previewTVC.tableTitle = "Which video should we play?"
        previewTVC.rowTitles = surprises.map { $0.title }
        previewTVC.completion = { index in
            Audio.instance.stop()
            Video.instance.play(surprises[index].video, from: self)
        }
        return previewTVC
    }
}
