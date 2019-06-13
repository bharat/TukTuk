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
        sync.notify = {
            DispatchQueue.main.async {
                self.updateUI()
            }
        }
    }

    func spinner(_ outlet: Outlet) -> UIActivityIndicatorView {
        return spinners[outlet.rawValue]
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if cloudProvider.isAuthenticated {
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    Outlet.allCases.forEach { outlet in
                        self.spinner(outlet).startAnimating()
                    }
                }

                SongManager.instance.loadLocal()
                SongManager.instance.loadCloud(from: self.cloudProvider)
                DispatchQueue.main.async {
                    self.spinner(.songsLocal).stopAnimating()
                    self.spinner(.songsCloud).stopAnimating()
                    self.updateUI()
                }

                MovieManager.instance.loadLocal()
                MovieManager.instance.loadCloud(from: self.cloudProvider)
                DispatchQueue.main.async {
                    self.spinner(.moviesLocal).stopAnimating()
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
        dispatchPrecondition(condition: .onQueue(.main))

        let songs = SongManager.instance
        let movies = MovieManager.instance

        counts[Outlet.songsCloud.rawValue].text = "\(songs.cloud.count)"
        counts[Outlet.songsLocal.rawValue].text = "\(songs.local.count)"
        counts[Outlet.moviesCloud.rawValue].text = "\(movies.cloud.count)"
        counts[Outlet.moviesLocal.rawValue].text = "\(movies.local.count)"

        if songs.local.count == songs.cloud.count || !sync.inProgress {
            spinner(.songsLocal).stopAnimating()
        }

        if movies.local.count == movies.cloud.count || !sync.inProgress {
            spinner(.moviesLocal).stopAnimating()
        }

        if sync.inProgress {
            progress.isHidden = false
            progress.setProgress(sync.progress, animated: true)
            syncButton.isHidden = true
            cancelButton.isHidden = false
        } else {
            UIView.animate(withDuration: 1.0) {
                self.progress.isHidden = true
            }
            cancelButton.isHidden = true
            cancelButton.setTitle("Cancel", for: .normal)

            syncButton.isHidden = false
            syncButton.isEnabled = !sync.inSync
        }
    }

    @IBAction func cancel(_ sender: Any) {
        sync.cancel()
        cancelButton.setTitle("Canceling...", for: .normal)
    }

    @IBAction func sync(_ sender: Any) {
        guard !sync.inProgress else { return }

        UIView.animate(withDuration: 0.5) {
            self.syncButton.isHidden = true
            self.cancelButton.isHidden = false
            self.progress.isHidden = false
            self.progress.setProgress(0, animated: false)
        }
        spinner(.songsLocal).startAnimating()
        spinner(.moviesLocal).startAnimating()
        sync.run()
        updateUI()
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
