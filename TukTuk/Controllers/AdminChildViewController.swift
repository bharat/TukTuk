//
//  AdminChildViewController.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 4/12/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation
import UIKit
import PopupDialog

class AdminChildViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if UserDefaults.standard.child == nil {
            let popup = PopupDialog(title: "Let's get started!", message: "First, select your child!")
            self.present(popup, animated: true)
        }

        collectionView.reloadData()
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Children.all.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChildCell", for: indexPath) as! ChildCell
        let child = Children.all[indexPath.row]
        cell.childImage.image = child.image
        cell.selectedOverlayImage.isHidden = child != UserDefaults.standard.child
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let currentChild = UserDefaults.standard.child
        let selectedChild = Children.all[indexPath.row]
        var popup: PopupDialog?

        if let currentChild = currentChild {
            if currentChild != selectedChild {
                popup = PopupDialog(title: "You're switching children!", message: "You're switching from \(currentChild.name) to \(selectedChild.name), this will delete any local songs and movies and you'll have to download them again")
                popup!.addButtons([
                    CancelButton(title: "Eek, don't do that") { },
                    DestructiveButton(title: "Yes, switch to \(selectedChild.name)") {
                        self.select(child: selectedChild)
                        Manager.songs.deleteAllLocal()
                        Manager.movies.deleteAllLocal()
                        Manager.images.deleteAllLocal()

                        let popup = PopupDialog(title: "Good job", message: "You chose \(selectedChild.name)! Now you need to download music again!")  {
                           self.tabBarController?.selectedIndex = 1
                        }
                        self.present(popup, animated: true)
                    }
                ])

            }
        } else {
            select(child: selectedChild)
            popup = PopupDialog(title: "Good job", message: "You chose \(selectedChild.name)! Next we'll download some music.")  {
               self.tabBarController?.selectedIndex = 1
            }
        }

        if let popup = popup {
            self.present(popup, animated: true)
        }
    }

    func select(child: Child) {
        UserDefaults.standard.child = child
        UIApplication.shared.setAlternateIconName("AppIcon_\(child.name)") { error in
            if error != nil {
                print("Error setting alternate icon name for \(child.name): \(String(describing: error))")
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var dim = self.view.frame.width
        return CGSize(width: dim, height: dim)
    }
}
