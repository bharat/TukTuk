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
import CollectionViewSlantedLayout

extension Bundle {
    static let Player = Bundle.media("Player")
}

extension TimeInterval {
    static let MovieInterval: TimeInterval = 2400
}

class SongViewController: UIViewController {
    @IBOutlet weak var songCollection: UICollectionView!
    @IBOutlet weak var songCollectionLayout: CollectionViewSlantedLayout!

    @IBOutlet weak var buttons: UIStackView!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var movieButton: UIButton!
    @IBOutlet weak var movieTimerLabel: UILabel!

    var preferredMovie: Movie?
    var preferredMiniGame: MiniGame?
    static let movies = Bundle.Player.movies()
    static let songs = Bundle.Player.songs()

    var showSongFilenames: Bool = false

    static func preload() {
        _ = [movies, songs]
    }

    var movieCountdown: TimeInterval = 0 {
        didSet {
            if movieCountdown == 0 {
                UIView.animate(withDuration: 0.75) {
                    self.movieButton.isHidden = false
                }
                movieCountdown = .MovieInterval
            }

            movieTimerLabel.text = "\(Int(movieCountdown))"
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // 3DTouch or a long press on the stop button will bring up an interface where you can
        // cue up a MiniGame or a Movie
        registerForPreviewing(with: self, sourceView: stopButton)
        let long = UILongPressGestureRecognizer(target: self, action: #selector(handleControlPanelGesture(gesture:)))
        long.minimumPressDuration = 5.0
        stopButton.addGestureRecognizer(long)
        stopButton.isEnabled = false

        songCollectionLayout.isFirstCellExcluded = true
        songCollectionLayout.isLastCellExcluded = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        movieCountdown = UserDefaults.standard.movieCountdown
        movieButton.isHidden = (movieCountdown > 0)

        NotificationCenter.default.addObserver(self, selector: #selector(appEnteredBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)

        songCollection.reloadData()
        songCollectionLayout.invalidateLayout()
    }

    override func viewWillDisappear(_ animated: Bool) {
        UserDefaults.standard.movieCountdown = movieCountdown
    }

    @objc func appEnteredBackground() {
        UserDefaults.standard.movieCountdown = movieCountdown
    }

    @IBAction func buttonTapped(_ sender: UIButton) {
        switch(sender) {
        case movieButton:
            AudioPlayer.stop()
            stopButton.isEnabled = false

            VideoPlayer.play(preferredMovie ?? SongViewController.movies.randomElement()!, from: self)
            movieButton.isHidden = true
            preferredMovie = nil

        case stopButton:
            AudioPlayer.stop()
            stopButton.isEnabled = false
            deselectAllSongs()
        default:
            ()
        }

        songCollectionLayout.redraw()
    }

    @objc func handleControlPanelGesture(gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            show(controlPanel(), sender: self)
        }
    }
}

extension SongViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        switch(previewingContext.sourceView) {
        case stopButton:
            show(controlPanel(), sender: self)
        default:
            break
        }
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        switch(previewingContext.sourceView) {
        case stopButton:
            return controlPanel()
        default:
            return nil
        }
    }

    func controlPanel() -> PopUpMenuViewController {
        let previewTVC = storyboard?.instantiateViewController(withIdentifier: "PopUpMenuVC") as! PopUpMenuViewController

        previewTVC.tableTitle = "Control Panel"
        previewTVC.groups = [
            MenuGroup(title: "Controls", id: "controls", choices: [showSongFilenames ? "Hide filenames" : "Show filenames"]),
            MenuGroup(title: "Cue up a movie", id: "movie", choices: SongViewController.movies.map { $0.title }),
            MenuGroup(title: "Cue up a MiniGame", id: "minigame", choices: MiniGames.all.map { $0.title })
        ]
        previewTVC.completion = { id, index in
            switch(id) {
            case "controls":
                self.showSongFilenames = !self.showSongFilenames

            case "movie":
                self.movieCountdown = 0
                self.preferredMovie = SongViewController.movies[index]

            case "minigame":
                self.preferredMiniGame = MiniGames.all[index].init()

            default:
                ()
            }
        }
        return previewTVC
    }
}

extension SongViewController: CollectionViewDelegateSlantedLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: CollectionViewSlantedLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGFloat {

        if let selected = collectionView.indexPathsForSelectedItems?.map({ $0.row }) {
            if selected.contains(indexPath.row) {
                return 400
            }
        }
        return 200
    }
}

extension SongViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        stopButton.isEnabled = false

        songCollectionLayout.redraw()

        if !VideoPlayer.isPlaying {
            if let preferredMiniGame = preferredMiniGame {
                show(preferredMiniGame.uivc, sender: self)
                self.preferredMiniGame = nil
                return
            }
            
            if Array(1...60).randomElement()! == 1 {
                show(MiniGames.all.randomElement()!.init().uivc, sender: self)
                return
            }

            stopButton.isEnabled = true

            let song = SongViewController.songs[indexPath.row]
            print("Playing song: \(song.title)")
            AudioPlayer.play(song, whilePlaying: {
                self.movieCountdown -= 1
            }, whenComplete: {
                self.deselectAllSongs()
            })
        }
    }

    func deselectAllSongs() {
        songCollection.indexPathsForSelectedItems?.forEach {
            songCollection.deselectItem(at: $0, animated: true)
        }
    }
}

let yOffsetSpeed: CGFloat = 150.0
let xOffsetSpeed: CGFloat = 100.0

extension SongViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let collectionView = songCollection else { return }
        guard let visibleCells = collectionView.visibleCells as? [SongCell] else { return }
        
        for parallaxCell in visibleCells {
            let yOffset = (collectionView.contentOffset.y - parallaxCell.frame.origin.y) / parallaxCell.imageHeight
            let xOffset = (collectionView.contentOffset.x - parallaxCell.frame.origin.x) / parallaxCell.imageWidth
            parallaxCell.offset(CGPoint(x: xOffset * xOffsetSpeed, y: yOffset * yOffsetSpeed))
        }
    }

}

extension SongViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return SongViewController.songs.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = songCollection.dequeueReusableCell(withReuseIdentifier: "SongCell", for: indexPath) as! SongCell
        let song = SongViewController.songs[indexPath.row]

        cell.image = song.image

//        cell.title.text = showSongFilenames ? song.title : ""
//        cell.title.layer.backgroundColor = UIColor.white.cgColor
//        cell.title.layer.cornerRadius = 3
//        cell.title.text = song.title

        return cell
    }
}

