//
//  AdminSyncTableViewController.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/3/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation
import UIKit
import PopupDialog
import GoogleSignIn

class AdminSyncTableViewController: UITableViewController {
    @IBOutlet var songsOnThisDeviceLabel: UILabel!
    @IBOutlet var songsInTheCloudLabel: UILabel!
    @IBOutlet var moviesOnThisDeviceLabel: UILabel!
    @IBOutlet var moviesInTheCloudLabel: UILabel!
    @IBOutlet var syncCancelButton: UIButton!
    @IBOutlet var syncButton: UIButton!
    @IBOutlet var syncProgress: UIProgressView!
    let sync = SyncEngine()

    override func viewDidLoad() {
        sync.notify = {
            DispatchQueue.main.async {
                self.updateUI()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if GoogleDrive.instance.isAuthenticated {
            loadFromCloud()
        } else {
            let popup = PopupDialog(title: "Let's get started", message: "It's pretty easy. First, log in to Google, then hit the Synchronize button") {
                GoogleDrive.instance.signIn(uiDelegate: self)
            }
            self.present(popup, animated: true, completion: nil)
        }
    }

    func loadFromCloud() {
        GoogleDrive.instance.getSongs() { songs in
            self.sync.cloudSongs = songs
            GoogleDrive.instance.getMovies() { movies in
                self.sync.cloudMovies = movies
                self.sync.calculate()
                self.updateUI()
            }
        }
    }

    func updateUI() {
        self.songsInTheCloudLabel.text = "\(sync.cloudSongs.count)"
        self.songsOnThisDeviceLabel.text = "\(LocalStorage.instance.songs.count)"
        self.moviesInTheCloudLabel.text = "\(sync.cloudMovies.count)"
        self.moviesOnThisDeviceLabel.text = "\(LocalStorage.instance.movies.count)"

        if sync.inProgress {
            syncProgress.isHidden = false
            syncProgress.setProgress(sync.progress, animated: true)
            syncButton.isHidden = true
            syncCancelButton.isHidden = false
        } else {
            UIView.animate(withDuration: 1.0) {
                self.syncProgress.isHidden = true
            }
            syncButton.isHidden = false
            syncCancelButton.isHidden = true
            syncCancelButton.titleLabel?.text = "Cancel"
        }
    }

    @IBAction func cancel(_ sender: Any) {
        syncCancelButton.titleLabel?.text = "Cancelling..."
        sync.cancel()
    }

    @IBAction func sync(_ sender: Any) {
        UIView.animate(withDuration: 0.5) {
            self.syncButton.isHidden = true
            self.syncCancelButton.isHidden = false
            self.syncProgress.isHidden = false
            self.syncProgress.setProgress(0, animated: false)
        }
        sync.calculate()
        sync.run()
        updateUI()
    }

    @IBAction func reset(_ sender: Any) {
        let popup = PopupDialog(title: "Are you sure?", message: "This will delete all downloaded songs and videos!")
        popup.addButtons([
            CancelButton(title: "Cancel") { },
            DefaultButton(title: "Ok") {
                LocalStorage.instance.deleteAllSongs()
                LocalStorage.instance.deleteAllMovies()
                self.updateUI()
            }
            ])
        self.present(popup, animated: true, completion: nil)
    }
}

extension AdminSyncTableViewController: GIDSignInUIDelegate {
}
