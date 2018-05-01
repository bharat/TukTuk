//
//  SurpriseTableViewController.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 4/30/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation

import UIKit

class SurpriseTableViewController: UITableViewController {
    var surprises: [Surprise] = []
    var songVC: SongViewController?

    @IBAction func dismiss(_ sender: Any) {
        presentingViewController?.dismiss(animated: true)
    }

    // MARK: UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return surprises.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SurpriseCell")!

        cell.textLabel?.text = surprises[indexPath.row].title
        return cell
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.dismiss(animated: true) {
            self.songVC?.playVideo(self.surprises[indexPath.row].movie)
        }
    }
}
