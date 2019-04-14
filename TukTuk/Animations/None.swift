//
//  None.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/12/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit

class None: Animation {
    var title: String = "None"

    required init() {
    }

    func animate(view: UIView, completion: @escaping ()->()) {
        completion()
    }
}
