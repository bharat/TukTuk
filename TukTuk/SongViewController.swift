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

    var preferredVideo: URL?
    var preferredMiniGame: MiniGame?

    var videoCountdown: TimeInterval = 0 {
        didSet {
            if videoCountdown < 0 {
                videoCountdown = 0
            }

            videoTimerLabel.text = "\(Int(videoCountdown))"

            if videoCountdown <= 0 {
                UIView.animate(withDuration: 1) {
                    self.videoTimerLabel.isHidden = true
                    self.videoButton.isHidden = false
                }
            } else {
                if !videoButton.isHidden {
                    self.videoTimerLabel.isHidden = false
                    self.videoButton.isHidden = true
                }
            }
        }
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        // 3DTouch or a long press on the stop button will bring up an interface where you can
        // start a surprise video
        registerForPreviewing(with: self, sourceView: stopButton)
        let long = UILongPressGestureRecognizer(target: self, action: #selector(handleVideoLongPress(gesture:)))
        long.minimumPressDuration = 5.0
        stopButton.addGestureRecognizer(long)

        videoButton.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        videoCountdown = UserDefaults.standard.double(forKey: "videoCountdown")
    }

    @IBAction func buttonTapped(_ sender: UIButton) {
        switch(sender) {
        case videoButton:
            AudioPlayer.stop()
            let video = preferredVideo ?? Catalog.instance.videos.random.video
            videoCountdown = 2400
            VideoPlayer.play(video, from: self)
            preferredVideo = nil
            disableStopButton()

        case stopButton:
            AudioPlayer.stop()
            disableStopButton()

        default:
            ()
        }

        UserDefaults.standard.setValue(videoCountdown, forKey: "videoCountdown")
        UserDefaults.standard.synchronize()
    }

    func enableStopButton() {
        stopButton.isEnabled = true
    }

    func disableStopButton() {
        stopButton.isEnabled = false
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if VideoPlayer.isPlaying == false {
            if preferredMiniGame != nil || Array(1...60).random == 1 {
                let miniGame = preferredMiniGame ?? MiniGames.random()
                show(miniGame.uivc, sender: self)
                preferredMiniGame = nil
                return
            }

            AudioPlayer.play(Catalog.instance.songs[indexPath.row].audio, tick: {
                self.videoCountdown -= 1
            })
            enableStopButton()

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

    @objc func handleVideoLongPress(gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            show(videoAndMiniGameChooser(), sender: self)
        }
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        switch(previewingContext.sourceView) {
        case stopButton:
            show(videoAndMiniGameChooser(), sender: self)
        default:
            break
        }
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        switch(previewingContext.sourceView) {
        case stopButton:
            return videoAndMiniGameChooser()
        default:
            return nil
        }
    }

    func videoAndMiniGameChooser() -> PreviewingTableViewController {
        let previewTVC = storyboard?.instantiateViewController(withIdentifier: "PreviewTableVC") as! PreviewingTableViewController

        previewTVC.tableTitle = "Which video should we play?"
        previewTVC.groups = [
            PreviewGroup(title: "Videos", id: "video", data: Catalog.instance.videos.map { $0.title }),
            PreviewGroup(title: "Mini Games", id: "minigame", data: MiniGames.all.map { $0.title })
        ]
        previewTVC.completion = { id, index in
            switch(id) {
            case "video":
                self.videoCountdown = 0
                self.preferredVideo = Catalog.instance.videos[index].video

            case "minigame":
                self.preferredMiniGame = MiniGames.all[index].init()

            default:
                ()
            }
        }
        return previewTVC
    }
}
