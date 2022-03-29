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
    case launchImages
}

let DESIRED_CONCURRENCY = 4

class AdminSyncTableViewController: UITableViewController {
    @IBOutlet var spinners: [UIActivityIndicatorView]!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var syncButton: UIButton!
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var statusCell: UITableViewCell!
    @IBOutlet weak var resetButton: UIButton!

    let cloudProvider: CloudProvider = GoogleDrive.instance
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

    func status(_ outlet: Outlet) -> UILabel {
        let indexPath: IndexPath = {
            switch outlet {
            case .songsLocal:
                return IndexPath(row: 0, section: 0)
            case .songsCloud:
                return IndexPath(row: 1, section: 0)
            case .moviesLocal:
                return IndexPath(row: 0, section: 1)
            case .moviesCloud:
                return IndexPath(row: 1, section: 1)
            case .launchImages:
                return IndexPath(row: 0, section: 2)
            }
        }()
        return tableView.cellForRow(at: indexPath)!.detailTextLabel!
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        statusMessages = []
        if cloudProvider.isAuthenticated {
            print("Cloud: authenticated")
            self.updateSyncStatus()
        } else {
            print("Cloud: not authenticated")
            cloudProvider.silentSignIn() { success in
                print("Cloud: silent sign-on returned \(success)")
                if success {
                    self.updateSyncStatus()
                } else {
                    let popup = PopupDialog(title: "Let's get started", message: "It's pretty easy. First, log in to Google, then hit the Synchronize button") {
                        print("Cloud: explicit sign-on requested")
                        self.cloudProvider.signIn(uiDelegate: self) {
                            self.updateSyncStatus()
                        }
                    }
                    self.present(popup, animated: true) {
                        self.updateSyncStatus()
                    }
                }
            }
        }
    }
    
    func updateSyncStatus() {
        print("Sync: updateSyncStatus")
        self.spinner(.songsCloud).startAnimating()
        self.spinner(.moviesCloud).startAnimating()
        syncButton.isEnabled = false

        DispatchQueue.global().async {
            Manager.songs.loadLocal()
            Manager.movies.loadLocal()
            self.updateUI()

            Manager.songs.loadCloud(from: self.cloudProvider) {
                self.spinner(.songsCloud).stopAnimating()
                self.status(.songsCloud).text = "\(Manager.songs.cloud.count)"
                self.updateUI()

                Manager.songs.brokenCloud.forEach { song in
                    if let diagnosis = song.malformedCloudDiagnosis {
                        self.updateUI(add: diagnosis)
                    }
                }
            }

            Manager.movies.loadCloud(from: self.cloudProvider) {
                self.spinner(.moviesCloud).stopAnimating()
                self.status(.moviesCloud).text = "\(Manager.movies.cloud.count)"
                self.updateUI()
            }
            
            Manager.images.loadCloud(from: self.cloudProvider) {
                self.spinner(.launchImages).stopAnimating()
                self.status(.launchImages).text = Manager.images.inSync ? "up to date" : "out of date"
            }
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

        status(.songsLocal).text = "\(Manager.songs.local.count)"
        status(.moviesLocal).text = "\(Manager.movies.local.count)"
        status(.launchImages).text = Manager.images.inSync ? "up to date" : "out of date"

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

        statusCell.isHidden = statusMessages.count == 0
        status.text = statusMessages.joined(separator: "\n")


        syncButton.isEnabled = !(Manager.songs.inSync && Manager.movies.inSync && Manager.images.inSync)
    }

    @IBAction func cancel(_ sender: Any) {
        cancelButton.setTitle("Canceling...", for: .normal)
        sync.cancel()
    }

    @IBAction func sync(_ sender: Any) {
        guard !sync.inProgress else { return }

        if sync.deleteCount <= 5 {
            reallySync()
            return
        }

        let popup = PopupDialog(title: "Are you sure?", message: "This sync will delete \(sync.deleteCount) songs and movies. Are you sure you want to continue?")
        popup.addButtons([
            CancelButton(title: "Cancel") { },
            DestructiveButton(title: "Ok") {
                self.reallySync()
            }
            ])
        self.present(popup, animated: true, completion: nil)
    }

    func reallySync() {
        syncButton.isHidden = true
        cancelButton.isHidden = false
        progress.isHidden = false
        resetButton.isEnabled = false
        status.numberOfLines = DESIRED_CONCURRENCY
        progress.setProgress(0, animated: false)
        spinner(.songsLocal).startAnimating()
        spinner(.moviesLocal).startAnimating()
        spinner(.launchImages).startAnimating()

        sync.run() {
            DispatchQueue.main.sync {
                self.syncButton.isHidden = false
                self.cancelButton.setTitle("Cancel", for: .normal)
                self.cancelButton.isHidden = true
                self.progress.isHidden = true
                self.resetButton.isEnabled = true
                self.status.text = nil
                self.tableView.headerView(forSection: 3)?.textLabel?.text = ""
                self.spinner(.songsLocal).stopAnimating()
                self.spinner(.moviesLocal).stopAnimating()
                self.spinner(.launchImages).stopAnimating()
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
