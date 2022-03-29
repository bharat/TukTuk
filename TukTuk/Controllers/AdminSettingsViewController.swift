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
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return 2
        case 2:
            return 1
        case 3:
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
            return "Movie and MiniGame Settings"
        case 2:
            return "Captain America MiniGame"
        case 3:
            return "Test Animations"
        default:
            fatalError("Unknown section: \(section)")
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PickerCell", for: indexPath)
            as! PickerCell

        cell.picker.delegate = cell

        switch indexPath {
        // Play Next
        case IndexPath(row: 0, section: 0):
            cell.title.text = "Movie"
            cell.detail.text = Settings.cuedMovie?.title ?? .emptyTitle
            cell.data = Manager.movies.local.sorted { $0.title < $1.title }
            cell.select = { obj in
                Settings.cuedMovie = obj as! Movie?
                self.redraw()
            }
        case IndexPath(row: 1, section: 0):
            cell.title.text = "MiniGame"
            cell.detail.text = Settings.cuedMiniGame?.title ?? .emptyTitle
            cell.data = MiniGames.all
            cell.select = { obj in
                Settings.cuedMiniGame = obj as! MiniGame?
                self.redraw()
            }

        // Movie And Mini Game Settings
        case IndexPath(row: 0, section: 1):
            cell.title.text = "Movie Frequency"
            cell.detail.text = UserDefaults.standard.movieFrequency.title
            cell.data = Array(stride(from:30, through:60, by:5)).map { Frequency(seconds: $0 * 60) }
            cell.canBeEmpty = false
            cell.select = { obj in
                UserDefaults.standard.movieFrequency = obj as! Frequency
                self.redraw()
            }

        case IndexPath(row: 1, section: 1):
            cell.title.text = "MiniGame Frequency"
            cell.detail.text = UserDefaults.standard.miniGameProbability.title
            cell.data = Array(stride(from:25, through:100, by:5)).map { Probability(denominator: $0) }
            cell.canBeEmpty = false
            cell.select = { obj in
                UserDefaults.standard.miniGameProbability = obj as! Probability
                self.redraw()
            }

        // Captain America MiniGame
        case IndexPath(row: 0, section: 2):
            cell.title.text = "Maze Level"
            cell.detail.text = "\(UserDefaults.standard.mazeLevel)"
            cell.data = CaptainAmerica.levels
            cell.canBeEmpty = false
            cell.select = { obj in
                UserDefaults.standard.mazeLevel = (obj as! CaptainAmerica.Level).level
                self.redraw()
            }
            
        case IndexPath(row: 0, section: 3):
            cell.title.text = "Welcome animations"
            cell.detail.text = .emptyTitle
            cell.data = Animations.all
            cell.canBeEmpty = false
            cell.select = { obj in
                let welcomeImageView = WelcomeViewController.createWelcomeImage(inside: self.view)
                self.view.addSubview(welcomeImageView)

                (obj as! Animation).animate(view: self.view) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        welcomeImageView.removeFromSuperview()
                        cell.detail.text = .emptyTitle
                        self.redraw()
                    }
                }
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
