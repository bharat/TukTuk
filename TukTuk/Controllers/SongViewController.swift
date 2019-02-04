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

extension Bundle {
    static let Player = Bundle.media("Player")
}

extension TimeInterval {
    static let VideoInterval: TimeInterval = 2400
}

class SongViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIViewControllerPreviewingDelegate {
    @IBOutlet weak var musicTable: UITableView!
    @IBOutlet weak var buttons: UIStackView!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var videoTimerLabel: UILabel!

    var preferredVideo: URL?
    var preferredMiniGame: MiniGame.Type?
    var videos = Bundle.Player.videos()
    let songs = Bundle.Player.songs().shuffled()

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
        stopButton.isEnabled = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        videoCountdown = UserDefaults.standard.videoCountdown
        videoButton.isHidden = (videoCountdown > 0)

        NotificationCenter.default.addObserver(self, selector: #selector(appEnteredBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        UserDefaults.standard.videoCountdown = videoCountdown
    }

    @objc func appEnteredBackground() {
        UserDefaults.standard.videoCountdown = videoCountdown
    }

    @IBAction func buttonTapped(_ sender: UIButton) {
        switch(sender) {
        case videoButton:
            AudioPlayer.stop()
            stopButton.isEnabled = false

            VideoPlayer.play(preferredVideo ?? videos.randomElement()!.video, from: self)
            videoButton.isHidden = true
            preferredVideo = nil

        case stopButton:
            AudioPlayer.stop()
            stopButton.isEnabled = false
            deselectAllSongs()
        default:
            ()
        }
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
            
            if Array(1...60).randomElement()! == 1 {
                show(MiniGames.all.randomElement()!.init().uivc, sender: self)
                return
            }

            stopButton.isEnabled = true
            musicTable.redraw()

            AudioPlayer.play(songs[indexPath.row].audio, whilePlaying: {
                self.videoCountdown -= 1
            }, whenComplete: {
                self.deselectAllSongs()
            })
        }
    }

    func deselectAllSongs() {
        if let selectedRow = musicTable.indexPathForSelectedRow {
            musicTable.deselectRow(at: selectedRow, animated: true)
            musicTable.redraw()
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
            PreviewGroup(title: "Videos", id: "video", data: videos.map { $0.title }),
            PreviewGroup(title: "Mini Games", id: "minigame", data: MiniGames.all.map { $0.title })
        ]
        previewTVC.completion = { id, index in
            switch(id) {
            case "video":
                self.videoCountdown = 0
                self.preferredVideo = self.videos[index].video

            case "minigame":
                self.preferredMiniGame = MiniGames.all[index]

            default:
                ()
            }
        }
        return previewTVC
    }
}
