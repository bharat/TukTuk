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
    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var videoTimerLabel: UILabel!

    var videoTimer: Timer?
    var videoCountdown: TimeInterval = 0 {
        didSet {
            videoTimerLabel.text = "\(Int(videoCountdown))"
        }
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        hideVideoButton()

        // 3DTouch or a long press on the stop button will bring up an interface where you can
        // start a surprise video
        registerForPreviewing(with: self, sourceView: stopButton)
        let long = UILongPressGestureRecognizer(target: self, action: #selector(handleVideoLongPress(gesture:)))
        long.minimumPressDuration = 5.0
        stopButton.addGestureRecognizer(long)
    }

    override func viewDidAppear(_ animated: Bool) {
        loadVideoCountdown()
    }

    @IBAction func buttonTapped(_ sender: UIButton) {
        switch(sender) {
        case videoButton:
            AudioPlayer.instance.stop()
            if let video = Catalog.instance.videos.random {
                VideoPlayer.instance.play(video.video, from: self)
            }
            disableStopButton()
            stopVideoTimer()
            hideVideoButton()

        case stopButton:
            AudioPlayer.instance.stop()
            disableStopButton()
            stopVideoTimer()
            saveVideoCountdown()

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
        if VideoPlayer.instance.isPlaying == false {
            if Array(1...120).random! == 1 {
                let minigame = Thor()
                minigame.play(on: self.view)
                return
            }

            AudioPlayer.instance.play(Catalog.instance.songs[indexPath.row].music, withCrossFade: true)
            enableStopButton()
            startVideoTimer()

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

    // MARK: Video

    func showVideoButton() {
        UIView.animate(withDuration: 1){
            self.videoButton.isHidden = false
            self.videoTimerLabel.isHidden = true
        }
    }

    func hideVideoButton() {
        UIView.animate(withDuration: 1) {
            self.videoTimerLabel.isHidden = false
            self.videoButton.isHidden = true
        }
    }

    func startVideoTimer() {
        videoTimer?.invalidate()
        videoTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(SongViewController.updateVideoCountdown)), userInfo: nil, repeats: true)
    }

    func stopVideoTimer() {
        videoTimer?.invalidate()
        videoTimer = nil
    }

    func loadVideoCountdown() {
        videoCountdown = UserDefaults.standard.double(forKey: "videoCountdown")
        print("video countdown \(videoCountdown)")
    }

    @objc func updateVideoCountdown() {
        if AudioPlayer.instance.isPlaying {
            videoCountdown -= 1

            if videoCountdown <= 0 {
                showVideoButton()
                videoCountdown = 1800
            }
        }
    }

    func saveVideoCountdown() {
        UserDefaults.standard.setValue(videoCountdown, forKey: "videoCountdown")
        UserDefaults.standard.synchronize()
    }

    @objc func handleVideoLongPress(gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            show(videoChooser(), sender: self)
        }
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        switch(previewingContext.sourceView) {
        case stopButton:
            show(videoChooser(), sender: self)
        default:
            break
        }
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        switch(previewingContext.sourceView) {
        case stopButton:
            return videoChooser()
        default:
            return nil
        }
    }

    func videoChooser() -> PreviewingTableViewController {
        let previewTVC = storyboard?.instantiateViewController(withIdentifier: "PreviewTableVC") as! PreviewingTableViewController
        let videos = Catalog.instance.videos

        previewTVC.tableTitle = "Which video should we play?"
        previewTVC.rowTitles = videos.map { $0.title }
        previewTVC.completion = { index in
            AudioPlayer.instance.stop()
            VideoPlayer.instance.play(videos[index].video, from: self)
        }
        return previewTVC
    }
}
