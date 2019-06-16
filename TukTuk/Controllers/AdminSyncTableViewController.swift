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

enum Outlet: Int, CaseIterable {
    case songsLocal = 0
    case songsCloud
    case moviesLocal
    case moviesCloud
}

class AdminSyncTableViewController: UITableViewController {
    @IBOutlet var counts: [UILabel]!
    @IBOutlet var spinners: [UIActivityIndicatorView]!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var syncButton: UIButton!
    @IBOutlet var progress: UIProgressView!

    let cloudProvider = GoogleDrive.instance
    let sync = SyncEngine(cloudProvider: GoogleDrive.instance)

    override func viewDidLoad() {
        sync.notify = self.updateUI
    }

    func spinner(_ outlet: Outlet) -> UIActivityIndicatorView {
        return spinners[outlet.rawValue]
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if cloudProvider.isAuthenticated {
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    self.spinner(.songsCloud).startAnimating()
                    self.spinner(.moviesCloud).startAnimating()
                }

                SongManager.instance.loadLocal()
                MovieManager.instance.loadLocal()
                self.updateUI()

                SongManager.instance.loadCloud(from: self.cloudProvider) {
                    self.spinner(.songsCloud).stopAnimating()
                    self.updateUI()
                }

                MovieManager.instance.loadCloud(from: self.cloudProvider) {
                    self.spinner(.moviesCloud).stopAnimating()
                    self.updateUI()
                }
            }
        } else {
            let popup = PopupDialog(title: "Let's get started", message: "It's pretty easy. First, log in to Google, then hit the Synchronize button") {
                self.cloudProvider.signIn(uiDelegate: self)
            }
            self.present(popup, animated: true, completion: nil)
        }

        self.updateUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        sync.cancel()
    }

    func updateUI() {
        guard Thread.isMainThread  else {
            DispatchQueue.main.async {
                self.updateUI()
            }
            return
        }

        let songs = SongManager.instance
        let movies = MovieManager.instance

        counts[Outlet.songsCloud.rawValue].text = "\(songs.cloud.count)"
        counts[Outlet.songsLocal.rawValue].text = "\(songs.local.count)"
        counts[Outlet.moviesCloud.rawValue].text = "\(movies.cloud.count)"
        counts[Outlet.moviesLocal.rawValue].text = "\(movies.local.count)"

        if sync.inProgress {
            progress.setProgress(sync.progress, animated: true)
        }
    }

    @IBAction func cancel(_ sender: Any) {
        cancelButton.setTitle("Canceling...", for: .normal)
        sync.cancel()
    }

    @IBAction func sync(_ sender: Any) {
        guard !sync.inProgress else { return }

        syncButton.isHidden = true
        cancelButton.isHidden = false
        progress.isHidden = false
        self.progress.setProgress(0, animated: false)
        spinner(.songsLocal).startAnimating()
        spinner(.moviesLocal).startAnimating()

        sync.run() {
            DispatchQueue.main.sync {
                self.syncButton.isHidden = false
                self.cancelButton.isHidden = true
                self.progress.isHidden = true
                self.cancelButton.setTitle("Cancel", for: .normal)
                self.spinner(.songsLocal).stopAnimating()
                self.spinner(.moviesLocal).stopAnimating()
            }
        }
    }

    @IBAction func reset(_ sender: Any) {
        let popup = PopupDialog(title: "Are you sure?", message: "This will delete all downloaded songs and videos!")
        popup.addButtons([
            CancelButton(title: "Cancel") { },
            DestructiveButton(title: "Ok") {
                SongManager.instance.deleteAllLocal()
                MovieManager.instance.deleteAllLocal()
                self.updateUI()
            }
            ])
        self.present(popup, animated: true, completion: nil)
    }
}

extension AdminSyncTableViewController: GIDSignInUIDelegate {
}
