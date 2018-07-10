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
    var preferredMiniGame: MiniGame.Type?

    var videoCountdown: TimeInterval = 0 {
        didSet {
            print("videoCountdown set to: \(videoCountdown)")

            if videoCountdown == 0 {
                UIView.animate(withDuration: 0.75) {
                    self.videoButton.isHidden = false
                }
                videoCountdown = .VideoInterval
            }

            videoTimerLabel.text = "\(Int(videoCountdown))"
            if videoCountdown.remainder(dividingBy: 10) == 0 {
                saveVideoCountdown()
            }
        }
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        // 3DTouch or a long press on the stop button will bring up an interface where you can
        // cue up a MiniGame or a Video
        registerForPreviewing(with: self, sourceView: stopButton)
        let long = UILongPressGestureRecognizer(target: self, action: #selector(handleVideoLongPress(gesture:)))
        long.minimumPressDuration = 5.0
        stopButton.addGestureRecognizer(long)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadVideoCountdown()
    }

    @IBAction func buttonTapped(_ sender: UIButton) {
        switch(sender) {
        case videoButton:
            AudioPlayer.stop()
            stopButton.isEnabled = false

            VideoPlayer.play(preferredVideo ?? Catalog.instance.videos.random.video, from: self)
            videoButton.isHidden = true
            preferredVideo = nil

        case stopButton:
            AudioPlayer.stop()
            stopButton.isEnabled = false

        default:
            ()
        }

        saveVideoCountdown()
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        stopButton.isEnabled = false
        
        if !VideoPlayer.isPlaying {
            if let preferredMiniGame = preferredMiniGame {
                show(preferredMiniGame.init().uivc, sender: self)
                self.preferredMiniGame = nil
                return
            }
            
            if Array(1...60).random == 1 {
                show(MiniGames.all.random.init().uivc, sender: self)
                return
            }

            AudioPlayer.play(Catalog.instance.songs[indexPath.row].audio) {
                self.videoCountdown -= 1
            }
            stopButton.isEnabled = true

            // Notify the tableView that we need to focus on the cell that was tapped
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

    // MARK: VideoCountdown

    func loadVideoCountdown() {
        videoCountdown = UserDefaults.standard.double(forKey: "videoCountdown")
        videoButton.isHidden = (videoCountdown > 0)
    }

    func resetVideoCountdown() {
        videoCountdown = .VideoInterval
    }

    func saveVideoCountdown() {
        UserDefaults.standard.setValue(videoCountdown, forKey: "videoCountdown")
        UserDefaults.standard.synchronize()
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
                self.preferredMiniGame = MiniGames.all[index]

            default:
                ()
            }
        }
        return previewTVC
    }
}
