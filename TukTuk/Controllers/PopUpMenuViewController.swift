//
//  PreviewingTableViewController.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 4/30/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation

import UIKit

struct MenuGroup {
    var title: String
    var id: String
    var choices: [String]
}

class PopUpMenuViewController: UITableViewController {
    @IBOutlet weak var titleLabel: UILabel!

    var tableTitle: String = ""
    var groups: [MenuGroup] = []
    var completion: (String, Int) -> (Void) = { (id, index) in }

    override func viewDidLoad() {
        titleLabel.text = tableTitle
    }

    @IBAction func dismiss(_ sender: Any) {
        presentingViewController?.dismiss(animated: true)
    }

    // MARK: UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return groups.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return groups[section].title
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups[section].choices.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell")!

        cell.textLabel?.text = groups[indexPath.section].choices[indexPath.row]
        return cell
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.dismiss(animated: true) {
            self.completion(self.groups[indexPath.section].id, indexPath.row)
        }
    }
}
