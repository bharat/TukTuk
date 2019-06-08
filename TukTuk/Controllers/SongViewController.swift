//
//  SongViewController.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 7/2/17.
//  Copyright © 2017 Menalto. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import CollectionViewSlantedLayout

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

    var stats = Stats()
    var songs: [Song] = [] {
        didSet {
            AudioPlayer.instance.stop()
            songCollection.reloadData()
            deselectAllSongs()
        }
    }

    var movieCountdown: TimeInterval = 0 {
        didSet {
            if movieCountdown == 0 {
                showMovieButton()
                movieCountdown = .MovieInterval
            }

            movieTimerLabel.text = "\(Int(movieCountdown))"
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Long press on the stop button will bring up an interface where you can
        // cue up a MiniGame or a Movie
        let long = UILongPressGestureRecognizer(target: self, action: #selector(showSettings(gesture:)))
        long.minimumPressDuration = 5.0
        stopButton.addGestureRecognizer(long)
        stopButton.isEnabled = false

        NotificationCenter.default.addObserver(self, selector: #selector(appEnteredBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadSongs()
        if songs.count == 0 {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "Admin", sender: self)
            }
        }

        movieCountdown = UserDefaults.standard.movieCountdown
        movieButton.isHidden = (movieCountdown > 0)
    }

    fileprivate func loadSongs() {
        if Set(songs.map { $0.title }) != Set(LocalStorage.instance.songs.keys) {
            songs = LocalStorage.instance.songs.values.sorted(by: { $0.title < $1.title })
        }
    }

    var lastFrame = CGRect(x: 0, y: 0, width: 0, height: 0)
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // if songCollection's frame changes, recalculate the slanting angle
        // TODO: figure out how to trigger this with observer pattern
        if songCollection.frame != lastFrame {
            songCollectionLayout.redraw()

            if let cells = songCollection.visibleCells as? [SongCell] {
                cells.forEach { cell in
                    cell.slantingAngle = songCollectionLayout.slantingAngle
                }
            }

            lastFrame = songCollection.frame
        }
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
            playMovie()

        case stopButton:
            stopSong()

        default:
            ()
        }
    }

    @objc func showSettings(gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            performSegue(withIdentifier: "Admin", sender: self)
        }
    }

    func showMovieButton() {
        if movieButton.isHidden {
            UIView.animate(withDuration: 0.75) {
                self.movieButton.isHidden = false
            }
        }
    }

    func playMovie() {
        deselectAllSongs()
        AudioPlayer.instance.stop()
        stats.stop()
        stopButton.isEnabled = false

        let movie = Settings.cuedMovie ?? Media.Player.movies.randomElement()!
        VideoPlayer.instance.play(movie, from: self)
        stats.start(movie: movie)

        Settings.cuedMovie = nil
        movieButton.isHidden = true
    }

    func stopSong() {
        stats.stop()
        deselectAllSongs()
        AudioPlayer.instance.stop()
        stopButton.isEnabled = false
    }

    func maybePlayMiniGame() -> Bool {
        var miniGame: MiniGame?
        if let cuedMiniGame = Settings.cuedMiniGame {
            miniGame = cuedMiniGame
            Settings.cuedMiniGame = nil
        } else if Array(1...60).randomElement()! == 1 {
            miniGame = MiniGames.all.randomElement()!
        }

        if let miniGame = miniGame {
            stopSong()
            stats.start(miniGame: miniGame)

            show(miniGame.uivc, sender: self)
            return true
        }

        return false
    }

    func playSong(_ song: Song) {
        if AudioPlayer.instance.isPlaying {
            stats.stop()
        }

        print("Playing song: \(song.title)")
        stats.start(song: song)
        AudioPlayer.instance.play(song, whilePlaying: {
            self.movieCountdown -= 1
            if Settings.cuedMovie != nil {
                self.showMovieButton()
            }
        }, whenComplete: {
            self.stats.complete()
            self.deselectAllSongs()
        })
    }

    func deselectAllSongs() {
        songCollection.indexPathsForSelectedItems?.forEach {
            songCollection.deselectItem(at: $0, animated: true)
        }
        songCollectionLayout.redraw()
    }
}

extension SongViewController: CollectionViewDelegateSlantedLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: CollectionViewSlantedLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGFloat {

        let width = collectionView.frame.width

        let cellHeight = { () -> CGFloat in
            switch width {
            case 375:       // iPhone variants
                return 200
            default:        // iPad
                return 300
            }
        }()

        if let cell = collectionView.cellForItem(at: indexPath), cell.isSelected {
            return cellHeight * 2
        }

        return cellHeight
    }
}


extension SongViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        stopButton.isEnabled = false

        songCollectionLayout.redraw()
        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)

        if VideoPlayer.instance.isStopped {
            if maybePlayMiniGame() {
                return
            }

            stopButton.isEnabled = true
            let song = songs[indexPath.row]
            playSong(song)
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
            if !parallaxCell.isSelected {
                let yOffset = (collectionView.contentOffset.y - parallaxCell.frame.origin.y) / parallaxCell.imageHeight
                let xOffset = (collectionView.contentOffset.x - parallaxCell.frame.origin.x) / parallaxCell.imageWidth
                parallaxCell.offset(CGPoint(x: xOffset * xOffsetSpeed, y: yOffset * yOffsetSpeed))
            }
        }
    }
}

extension SongViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return songs.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = songCollection.dequeueReusableCell(withReuseIdentifier: "SongCell", for: indexPath) as! SongCell
        let song = songs[indexPath.row]

        cell.image = song.image
        cell.title.text = song.title

        if let layout = collectionView.collectionViewLayout as? CollectionViewSlantedLayout {
            cell.slantingAngle = layout.slantingAngle
        }

        return cell
    }
}

