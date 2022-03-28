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
import PopupDialog
import TOPasscodeViewController
import BiometricAuthentication

class SongViewController: UIViewController {
    @IBOutlet weak var songCollection: UICollectionView!
    @IBOutlet weak var songCollectionLayout: CollectionViewSlantedLayout!
    @IBOutlet weak var buttons: UIStackView!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var movieButton: UIButton!
    @IBOutlet weak var movieTimerLabel: UILabel!

    var songPlayer = SongPlayer()
    var stats = Stats()
    var songs: [Song] = [] {
        didSet {
            AudioPlayer.instance.stop()
            songCollection.reloadData()
            deselectAllSongs()
        }
    }

    var movies: [Movie] = []
    var movieCountdown: Int = 0 {
        didSet {
            if movieCountdown == 0 {
                showMovieButton()
                movieCountdown = UserDefaults.standard.movieFrequency.seconds
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
        let long = UILongPressHapticFeedbackGestureRecognizer(target: self, action: #selector(settingsGesture(gesture:)))
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

        prepareView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
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
    
    @IBAction func unwindToSongs(unwindSegue: UIStoryboardSegue) {
        prepareView()
    }
    
    func prepareView() {
        print("SongView: preparing view")
        songs = Manager.songs.local.sorted {
            $0.title < $1.title
        }

        movies = Manager.movies.local.sorted {
            $0.title < $1.title
        }

        if songs.isEmpty {
            let popup = PopupDialog(title: "Oh no, there are no songs!", message: "Let's download some from the cloud!") {
                self.showSettings()
            }
            popup.addButton(DefaultButton(title: "Ok") { })
            self.present(popup, animated: true, completion: nil)
        }

        movieCountdown = UserDefaults.standard.movieCountdown
        movieButton.isHidden = (movieCountdown > 0)
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

    @objc func settingsGesture(gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            showSettings()
        }
    }
    
    func showSettings() {
        stopSong()
        
        BioMetricAuthenticator.authenticateWithBioMetrics(reason: "") { (result) in
            switch result {
            case .success(_):
                self.performSegue(withIdentifier: "Admin", sender: self)
            case .failure(_):
                let passcode = TOPasscodeViewController(style: .translucentDark, passcodeType: .sixDigits)
                passcode.delegate = self
                self.present(passcode, animated: true, completion: {})
            }
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
        songPlayer.stop()
        stopButton.isEnabled = false

        let movie = Settings.cuedMovie ?? movies.randomElement()!
        if let video = movie.video {
            VideoPlayer.instance.play(video.url, from: self)
            stats.start(movie: movie)
        }

        Settings.cuedMovie = nil
        movieButton.isHidden = true
    }

    func playSong(_ song: Song, on cell: SongCell) {
        songPlayer.play(song, on: cell, whilePlaying: {
            self.movieCountdown -= 1
            if Settings.cuedMovie != nil {
                self.showMovieButton()
            }
        }, whenComplete: {
            if song.video != nil {
                cell.videoLayer.player = nil
            }
        })
    }

    func stopSong() {
        deselectAllSongs()
        songPlayer.stop()
        stopButton.isEnabled = false
    }

    func maybePlayMiniGame() -> Bool {
        var miniGame: MiniGame?
        if let cuedMiniGame = Settings.cuedMiniGame {
            miniGame = cuedMiniGame
            Settings.cuedMiniGame = nil
        } else if UserDefaults.standard.miniGameProbability.outcome {
            miniGame = MiniGames.all.randomElement()!
        }

        if let miniGame = miniGame {
            stopSong()
            stats.start(miniGame: miniGame)

            miniGame.uivc.modalPresentationStyle = .fullScreen
            show(miniGame.uivc, sender: self)
            return true
        }

        return false
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
            let cell = collectionView.cellForItem(at: indexPath) as! SongCell

            playSong(song, on: cell)
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
        let song = songs[indexPath.row]
        let cell = songCollection.dequeueReusableCell(withReuseIdentifier: "SongCell", for: indexPath) as! SongCell
        
        cell.image = song.uiImage ?? UIImage()
        cell.title.text = song.title

        DispatchQueue.main.async {
            self.songPlayer.maybeReattachVideo(song, to: cell)
        }

        if let layout = collectionView.collectionViewLayout as? CollectionViewSlantedLayout {
            cell.slantingAngle = layout.slantingAngle
        }

        return cell
    }
}

extension SongViewController: TOPasscodeViewControllerDelegate {
    func didTapCancel(in passcodeViewController: TOPasscodeViewController) {
        self.dismiss(animated: true, completion: {})
    }
    
    func passcodeViewController(_ passcodeViewController: TOPasscodeViewController, isCorrectCode code: String) -> Bool {
        return code == "192837"
    }
    
    func didInputCorrectPasscode(in passcodeViewController: TOPasscodeViewController) {
        self.dismiss(animated: true) {
            self.performSegue(withIdentifier: "Admin", sender: self)
        }
    }
}
