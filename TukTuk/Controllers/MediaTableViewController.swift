//
//  MediaTableViewController.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/3/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation
import UIKit
import GoogleSignIn
import GoogleAPIClientForREST

class MediaTableViewController: UITableViewController {
    @IBOutlet var onDeviceSongCount: UILabel!
    @IBOutlet var googleDriveSongCount: UILabel!
    @IBOutlet var googleDriveSpinner: UIActivityIndicatorView!

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        GoogleDrive.instance.signIn(uiDelegate: self)
        onDeviceSongCount.text = "\(Songs.instance.songs.count)"
        updateGoogleDriveSongCount()
        // enable sync button based on checksum
    }

    fileprivate func updateGoogleDriveSongCount() {
        googleDriveSpinner.startAnimating()
        googleDriveSpinner.isHidden = false
        googleDriveSongCount.isHidden = true
        GoogleDrive.instance.listSongs() {
            self.googleDriveSpinner.stopAnimating()
            self.googleDriveSpinner.isHidden = true
            self.googleDriveSongCount.isHidden = false
            self.googleDriveSongCount.text = "\(GoogleDrive.instance.songs.count)"
        }
    }
    
    @IBAction func sync(_ sender: Any) {
        DispatchQueue.main.async {
            SyncEngine.instance.start(notify: {
                DispatchQueue.main.async {
                    self.onDeviceSongCount.text = "\(Songs.instance.songs.count)"
                }
            })
        }
    }

    @IBAction func deleteSongs(_ sender: Any) {
        Songs.instance.removeAll()
    }
}

extension MediaTableViewController: GIDSignInUIDelegate {
}
