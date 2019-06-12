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
    @IBOutlet var syncCancelButton: UIButton!
    @IBOutlet var syncButton: UIButton!
    @IBOutlet var syncProgress: UIProgressView!

    let cloud = GoogleDrive.instance
    let sync = SyncEngine(cloudProvider: GoogleDrive.instance)

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
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    Outlet.allCases.forEach { outlet in
                        self.spin(for: outlet)
                    }
                }
                Songs.instance.load(from: self.cloud)
                DispatchQueue.main.async {
                    self.stopSpinning(for: .songsLocal)
                    self.stopSpinning(for: .songsCloud)
                    self.updateUI()
                }
                Movies.instance.load(from: self.cloud)
                DispatchQueue.main.async {
                    self.stopSpinning(for: .moviesLocal)
                    self.stopSpinning(for: .moviesCloud)
                    self.updateUI()
                }
            }
        } else {
            let popup = PopupDialog(title: "Let's get started", message: "It's pretty easy. First, log in to Google, then hit the Synchronize button") {
                self.cloud.signIn(uiDelegate: self)
            }
            self.present(popup, animated: true, completion: nil)
        }

        self.updateUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        sync.cancel()
    }

    fileprivate func spin(for outlet: Outlet) {
        spinners[outlet.rawValue].startAnimating()
        spinners[outlet.rawValue].isHidden = false
    }

    fileprivate func stopSpinning(for outlet: Outlet) {
        spinners[outlet.rawValue].stopAnimating()
        spinners[outlet.rawValue].isHidden = true
    }

    func updateUI() {
        dispatchPrecondition(condition: .onQueue(.main))

        let songs = Songs.instance
        let movies = Movies.instance

        counts[Outlet.songsCloud.rawValue].text = "\(songs.cloud.count)"
        counts[Outlet.songsLocal.rawValue].text = "\(songs.local.count)"
        counts[Outlet.moviesCloud.rawValue].text = "\(movies.cloud.count)"
        counts[Outlet.moviesLocal.rawValue].text = "\(movies.local.count)"

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
            syncButton.isEnabled = !sync.inSync
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
                Songs.instance.deleteAllLocal()
                Movies.instance.deleteAllLocal()
                self.updateUI()
            }
            ])
        self.present(popup, animated: true, completion: nil)
    }
}

extension AdminSyncTableViewController: GIDSignInUIDelegate {
}
