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

    override func viewDidLoad() {
        super.viewDidLoad()

        welcomeImageView = UIImageView(frame: view.frame)
        welcomeImageView.contentMode = .scaleAspectFill
        welcomeImageView.clipsToBounds = true
        welcomeImageView.image = #imageLiteral(resourceName: "Welcome_BharatAndBettina")
        welcomeImageView.layer.borderWidth = 8
        welcomeImageView.layer.borderColor = UIColor.black.cgColor
        welcomeImageView.layer.cornerRadius = 0
        welcomeImageView.isUserInteractionEnabled = true
        view.addSubview(welcomeImageView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleWelcomeTap(sender:)))
        welcomeImageView.addGestureRecognizer(tap)

        let long = UILongPressGestureRecognizer(target: self, action: #selector(showSettings(gesture:)))
        long.minimumPressDuration = 5.0
        welcomeImageView.addGestureRecognizer(long)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Useful for quickly jumping to a specific minigame
        //        let minigame = CaptainAmerica()
        //        minigame.uivc.modalPresentationStyle = .fullScreen
        //        show(minigame.uivc, sender: self)
        
        // Or skipping the welcome screen
                self.performSegue(withIdentifier: "Songs", sender: self)
    }

    @objc func handleWelcomeTap(sender: UITapGestureRecognizer) {
        sender.isEnabled = false

        // Useful shortcut for development
        // Settings.cuedAnimation = FaceBalls()

        // Run a random welcome animation, or a preset if specified
        let animation = Settings.cuedAnimation ?? Animations.all.randomElement()!
        Settings.cuedAnimation = nil
        animation.animate(view: self.welcomeImageView) {
            self.performSegue(withIdentifier: "Songs", sender: self)

            // It's useful to re-enable this since in the simulator you can hit escape
            // and go back to the welcome view and run the animation again
            sender.isEnabled = true
        }
    }

    @objc func showSettings(gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            performSegue(withIdentifier: "Admin", sender: self)
        }
    }
}
