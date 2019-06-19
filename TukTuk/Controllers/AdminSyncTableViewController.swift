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

let DESIRED_CONCURRENCY = 4

class AdminSyncTableViewController: UITableViewController {
    @IBOutlet var counters: [UILabel]!
    @IBOutlet var spinners: [UIActivityIndicatorView]!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var syncButton: UIButton!
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var statusCell: UITableViewCell!
    @IBOutlet weak var resetButton: UIButton!

    let cloudProvider = GoogleDrive.instance
    let sync = SyncEngine(cloudProvider: GoogleDrive.instance, concurrency: DESIRED_CONCURRENCY)
    var statusMessages: [String] = []

    override func viewDidLoad() {
        sync.notifyStart = { msg in
            self.updateUI(add: msg)
        }
        sync.notifyStop = { msg in
            self.updateUI(remove: msg)
        }
    }

    func spinner(_ outlet: Outlet) -> UIActivityIndicatorView {
        return spinners[outlet.rawValue]
    }

    func counter(_ outlet: Outlet) -> UILabel {
        return counters[outlet.rawValue]
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if cloudProvider.isAuthenticated {
            self.spinner(.songsCloud).startAnimating()
            self.spinner(.moviesCloud).startAnimating()
            syncButton.isEnabled = false

            DispatchQueue.global().async {
                Manager.songs.loadLocal()
                Manager.movies.loadLocal()
                self.updateUI()

                Manager.songs.loadCloud(from: self.cloudProvider) {
                    self.spinner(.songsCloud).stopAnimating()
                    self.counter(.songsCloud).text = "\(Manager.songs.cloud.count)"
                    self.updateUI()
                }

                Manager.movies.loadCloud(from: self.cloudProvider) {
                    self.spinner(.moviesCloud).stopAnimating()
                    self.counter(.moviesCloud).text = "\(Manager.movies.cloud.count)"
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

    func updateUI(add: String? = nil, remove: String? = nil) {
        guard Thread.isMainThread  else {
            DispatchQueue.main.async {
                self.updateUI(add: add, remove: remove)
            }
            return
        }

        counter(.songsLocal).text = "\(Manager.songs.local.count)"
        counter(.moviesLocal).text = "\(Manager.movies.local.count)"

        if sync.inProgress {
            progress.setProgress(sync.progress, animated: true)
        }

        if let add = add {
            statusMessages.append(add)
        }
        if let remove = remove {
            statusMessages.removeAll { msg in
                msg == remove
            }
        }

        status.text = statusMessages.joined(separator: "\n")

        syncButton.isEnabled = !(Manager.songs.inSync && Manager.movies.inSync)
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
        statusCell.isHidden = false
        resetButton.isEnabled = false
        status.numberOfLines = DESIRED_CONCURRENCY
        progress.setProgress(0, animated: false)
        spinner(.songsLocal).startAnimating()
        spinner(.moviesLocal).startAnimating()

        sync.run() {
            DispatchQueue.main.sync {
                self.syncButton.isHidden = false
                self.cancelButton.setTitle("Cancel", for: .normal)
                self.cancelButton.isHidden = true
                self.progress.isHidden = true
                self.statusCell.isHidden = true
                self.resetButton.isEnabled = true
                self.status.text = nil
                self.tableView.headerView(forSection: 3)?.textLabel?.text = ""
                self.spinner(.songsLocal).stopAnimating()
                self.spinner(.moviesLocal).stopAnimating()
                self.statusMessages = []
            }
        }
    }

    @IBAction func reset(_ sender: Any) {
        let popup = PopupDialog(title: "Are you sure?", message: "This will delete all downloaded songs and videos!")
        popup.addButtons([
            CancelButton(title: "Cancel") { },
            DestructiveButton(title: "Ok") {
                Manager.songs.deleteAllLocal()
                Manager.movies.deleteAllLocal()
                self.updateUI()
            }
            ])
        self.present(popup, animated: true, completion: nil)
    }
}

extension AdminSyncTableViewController: GIDSignInUIDelegate {
}
