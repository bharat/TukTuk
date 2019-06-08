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
    @IBOutlet var onThisDeviceLabel: UILabel!
    @IBOutlet var inTheCloudLabel: UILabel!
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
        GoogleDrive.instance.signIn(uiDelegate: self)

        GoogleDrive.instance.getSongs() { songs in
            self.sync.cloud = songs
            self.sync.recalculate()
            self.updateUI()
        }
    }

    func updateUI() {
        self.inTheCloudLabel.text = "\(sync.cloud.count)"
        self.onThisDeviceLabel.text = "\(LocalStorage.instance.songs.count)"

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
        }
    }

    @IBAction func cancel(_ sender: Any) {
        sync.cancel()
    }

    @IBAction func sync(_ sender: Any) {
        UIView.animate(withDuration: 0.5) {
            self.syncButton.isHidden = true
            self.syncCancelButton.isHidden = false
            self.syncProgress.isHidden = false
            self.syncProgress.setProgress(0, animated: false)
        }
        sync.recalculate()
        sync.run()
        updateUI()
    }

    @IBAction func reset(_ sender: Any) {
        let popup = PopupDialog(title: "Are you sure?", message: "This will delete all downloaded songs")
        popup.addButtons([
            CancelButton(title: "Cancel") { },
            DefaultButton(title: "Ok") {
                LocalStorage.instance.deleteAllSongs()
                self.updateUI()
            }
            ])
        self.present(popup, animated: true, completion: nil)
    }
}

extension AdminSyncTableViewController: GIDSignInUIDelegate {
}
