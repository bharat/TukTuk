//
//  None.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/4/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation
import UIKit

class None: Animation {
    var title = "None"

    required init() {
    }

    func animate(view: UIView, completion: @escaping ()->()) {
        completion()
    }

}
