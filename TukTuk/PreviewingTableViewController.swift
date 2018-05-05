//
//  SurpriseTableViewController.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 4/30/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation

import UIKit

class PreviewingTableViewController: UITableViewController {
    var titles: [String] = []
    var completion: (Int) -> (Void) = { _ in }

    @IBAction func dismiss(_ sender: Any) {
        presentingViewController?.dismiss(animated: true)
    }

    // MARK: UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SurpriseCell")!

        cell.textLabel?.text = titles[indexPath.row]
        return cell
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.dismiss(animated: true) {
            self.completion(indexPath.row)
        }
    }
}
