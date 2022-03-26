//
//  AdminViewController.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 3/20/22.
//  Copyright © 2022 Menalto. All rights reserved.
//

import Foundation
import TOPasscodeViewController

class AdminViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        let passcode = TOPasscodeViewController(style: .translucentDark, passcodeType: .sixDigits)
        passcode.delegate = self
        self.present(passcode, animated: true, completion: {})
    }
    
    @IBAction func done(_ sender: Any) {
        self.dismiss(animated: true)
    }
}

extension AdminViewController: TOPasscodeViewControllerDelegate {
    func didTapCancel(in passcodeViewController: TOPasscodeViewController) {
        // Dismiss the passcode modal, then the admin modal itself
        self.dismiss(animated: true) {
            self.performSegue(withIdentifier: "unwindToSongs", sender: self)
        }
    }
    
    func passcodeViewController(_ passcodeViewController: TOPasscodeViewController, isCorrectCode code: String) -> Bool {
        return code == "192837"
    }
}
