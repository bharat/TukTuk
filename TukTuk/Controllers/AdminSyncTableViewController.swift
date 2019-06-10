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

enum Outlet: Int {
    case songsLocal = 0
    case songsCloud
    case moviesLocal
    case moviesCloud
}

class AdminSyncTableViewController: UITableViewController {
    @IBOutlet var counts: [UILabel]!
    @IBOutlet var spinners: [UIActivityIndicatorView]!
    @IBOutlet var syncCancelButton: UIButton!
    @IBOutlet var syncButton: UIButton!
    @IBOutlet var syncProgress: UIProgressView!

    let sync = SyncEngine()
    let cloud = GoogleDrive.instance

    override func viewDidLoad() {
        sync.notify = {
            DispatchQueue.main.async {
                self.updateUI()
            }
        }

        counts.sort { $0.tag < $1.tag }
        spinners.sort { $0.tag < $1.tag }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if cloud.isAuthenticated {
            cloud.getSongs() { songs in
                self.sync.cloudSongs = songs
                self.updateUI()
            }
            self.cloud.getMovies() { movies in
                self.sync.cloudMovies = movies
                self.updateUI()
            }
        } else {
            let popup = PopupDialog(title: "Let's get started", message: "It's pretty easy. First, log in to Google, then hit the Synchronize button") {
                self.cloud.signIn(uiDelegate: self)
            }
            self.present(popup, animated: true, completion: nil)
        }
    }

    fileprivate func updateCount(for outlet: Outlet, from data: Int?) {
        let spinner = spinners[outlet.rawValue]
        let count = counts[outlet.rawValue]

        if let data = data {
            spinner.isHidden = true
            spinner.stopAnimating()
            count.isHidden = false
            count.text = "\(data)"
        } else {
            spinner.isHidden = false
            spinner.startAnimating()
            count.isHidden = true
            count.text = "??"
        }
    }

    func updateUI() {
        updateCount(for: .songsCloud, from: sync.cloudSongs?.count)
        updateCount(for: .songsLocal, from: LocalStorage.instance.songs?.count)
        updateCount(for: .moviesCloud, from: sync.cloudMovies?.count)
        updateCount(for: .moviesLocal, from: LocalStorage.instance.movies?.count)

        if sync.inProgress {
            syncProgress.isHidden = false
            syncProgress.setProgress(sync.progress, animated: true)
            syncButton.isHidden = true
            syncCancelButton.isHidden = false
        } else {
            UIView.animate(withDuration: 1.0) {
                self.syncProgress.isHidden = true
            }
            syncCancelButton.isHidden = true
            syncCancelButton.setTitle("Cancel", for: .normal)

            syncButton.isHidden = false
            syncButton.isEnabled = sync.syncRequired
        }
    }

    @IBAction func cancel(_ sender: Any) {
        sync.cancel()
        syncCancelButton.setTitle("Canceling...", for: .normal)
    }

    @IBAction func sync(_ sender: Any) {
        UIView.animate(withDuration: 0.5) {
            self.syncButton.isHidden = true
            self.syncCancelButton.isHidden = false
            self.syncProgress.isHidden = false
            self.syncProgress.setProgress(0, animated: false)
        }
        sync.run() {
            DispatchQueue.main.async {
                self.updateUI()
            }
        }
        updateUI()
    }

    @IBAction func reset(_ sender: Any) {
        let popup = PopupDialog(title: "Are you sure?", message: "This will delete all downloaded songs and videos!")
        popup.addButtons([
            CancelButton(title: "Cancel") { },
            DestructiveButton(title: "Ok") {
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
