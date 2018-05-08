//
//  WelcomeViewController.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/7/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit

class WelcomeViewController: UIViewController, UIViewControllerPreviewingDelegate {
    var preferred: Animation?
    var welcomeImageView = UIImageView()

    // UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        welcomeImageView = UIImageView(frame: view.frame)
        welcomeImageView.contentMode = .scaleAspectFill
        welcomeImageView.clipsToBounds = true
        welcomeImageView.image = #imageLiteral(resourceName: "Welcome")
        welcomeImageView.layer.borderWidth = 8
        welcomeImageView.layer.borderColor = UIColor.black.cgColor
        welcomeImageView.layer.cornerRadius = 0
        welcomeImageView.isUserInteractionEnabled = true
        view.addSubview(welcomeImageView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleWelcomeTap(sender:)))
        welcomeImageView.addGestureRecognizer(tap)

        // 3DTouch or a long press on the welcome image will bring up an interface where you can
        // choose which animation will play
        registerForPreviewing(with: self, sourceView: welcomeImageView)
        let long = UILongPressGestureRecognizer(target: self, action: #selector(handleWelcomeLongPress(gesture:)))
        long.minimumPressDuration = 5.0
        welcomeImageView.addGestureRecognizer(long)
    }

    @objc func handleWelcomeTap(sender: UITapGestureRecognizer) {
        Audio.instance.play(Catalog.default.welcomeSong)

        // Run a random welcome animation, or a preset if specified
        let animation = preferred ?? Animations.random
        animation.animate(view: self.welcomeImageView) {
            self.performSegue(withIdentifier: "SongViewController", sender: self)
        }
    }

    // UIViewControllerPreviewingDelegate

    @objc func handleWelcomeLongPress(gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            show(animationChooser(), sender: self)
        }
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(animationChooser(), sender: self)
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        return animationChooser()
    }

    func animationChooser() -> PreviewingTableViewController {
        let previewTVC = storyboard?.instantiateViewController(withIdentifier: "PreviewTableVC") as! PreviewingTableViewController
        previewTVC.tableTitle = "Choose the welcome animation"
        previewTVC.rowTitles = Animations.all.map { $0.title }
        previewTVC.completion = { index in
            self.preferred = Animations.all[index].init()
        }
        return previewTVC
    }
}
