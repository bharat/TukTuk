//
//  WelcomeViewController.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/7/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit

class WelcomeViewController: UIViewController {
    var welcomeImageView = UIImageView()
    
    static func createWelcomeImage(inside parent: UIView) -> UIImageView {
        let view = UIImageView(frame: parent.frame)
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.image = Manager.images.data["Welcome"]?.uiImage ?? #imageLiteral(resourceName: "Welcome_BharatAndBettina")
        view.layer.borderWidth = 8
        view.layer.borderColor = UIColor.black.cgColor
        view.layer.cornerRadius = 0
        view.isUserInteractionEnabled = true
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        welcomeImageView = WelcomeViewController.createWelcomeImage(inside: view)
        view.addSubview(welcomeImageView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleWelcomeTap(sender:)))
        welcomeImageView.addGestureRecognizer(tap)

        let long = UILongPressGestureRecognizer(target: self, action: #selector(skipToSongs(gesture:)))
        long.minimumPressDuration = 2.0
        welcomeImageView.addGestureRecognizer(long)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Debug functionality
        //
        // Useful for quickly jumping to a specific minigame
        //        let minigame = CaptainAmerica()
        //        minigame.uivc.modalPresentationStyle = .fullScreen
        //        show(minigame.uivc, sender: self)
        //
        // Or skipping the welcome screen
        //        self.performSegue(withIdentifier: "Songs", sender: self)
    }

    @objc func handleWelcomeTap(sender: UITapGestureRecognizer) {
        sender.isEnabled = false

        // Useful shortcut for development
        // Settings.cuedAnimation = FaceBalls()

        // Run a random welcome animation, or a preset if specified
        Animations.all.randomElement()!.animate(view: self.welcomeImageView) {
            self.performSegue(withIdentifier: "Songs", sender: self)

            // It's useful to re-enable this since in the simulator you can hit escape
            // and go back to the welcome view and run the animation again
            sender.isEnabled = true
        }
    }

    @objc func skipToSongs(gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            performSegue(withIdentifier: "Songs", sender: self)
        }
    }
}
