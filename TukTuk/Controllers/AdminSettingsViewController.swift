//
//  AdminSettingsViewController.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 4/12/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation
import UIKit

extension String {
    static var emptyTitle = "--"
}

class AdminSettingsViewController: UITableViewController {
    @IBAction func done() {
        dismiss(animated: true, completion: {})
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 3
        case 1:
            return 1
        default:
            fatalError("Unknown section: \(section)")
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch(section) {
        case 0:
            return "Play Next..."
        case 1:
            return "Captain America Mini Game"
        default:
            fatalError("Unknown section: \(section)")
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PickerCell", for: indexPath)
            as! PickerCell

        cell.picker.delegate = cell

        switch indexPath {
        case IndexPath(row: 0, section: 0):
            cell.title.text = "Animation"
            cell.detail.text = Settings.cuedAnimation?.title ?? .emptyTitle
            cell.data = Animations.all
            cell.picker.showsSelectionIndicator = true
            cell.select = { obj in
                Settings.cuedAnimation = obj as! Animation?
                self.redraw()
            }
        case IndexPath(row: 1, section: 0):
            cell.title.text = "Movie"
            cell.detail.text = Settings.cuedMovie?.title ?? .emptyTitle
            cell.data = Movies.instance.local.sorted { $0.title < $1.title }
            cell.select = { obj in
                Settings.cuedMovie = obj as! Movie?
                self.redraw()
            }
        case IndexPath(row: 2, section: 0):
            cell.title.text = "Mini Game"
            cell.detail.text = Settings.cuedMiniGame?.title ?? .emptyTitle
            cell.data = MiniGames.all
            cell.select = { obj in
                Settings.cuedMiniGame = obj as! MiniGame?
                self.redraw()
            }
        case IndexPath(row: 0, section: 1):
            cell.title.text = "Maze Level"
            cell.detail.text = "\(UserDefaults.standard.mazeLevel)"
            cell.data = CaptainAmerica.levels
            cell.canBeEmpty = false
            cell.select = { obj in
                UserDefaults.standard.mazeLevel = (obj as! CaptainAmerica.Level).level
                self.redraw()
            }
        default:
            fatalError("Bad indexPath: \(indexPath)")
        }
        return cell
    }

    func redraw() {
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! PickerCell
        cell.showPicker()
        redraw()
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! PickerCell
        cell.hidePicker()
        redraw()
    }
}
