//
//  UITableView.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 7/10/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit

extension UITableView {
    func redraw() {
        beginUpdates()
        endUpdates()
    }
}
