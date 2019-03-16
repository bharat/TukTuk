//
//  CollectionViewSlantedLayout.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 3/16/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation
import CollectionViewSlantedLayout

extension CollectionViewSlantedLayout {
    func redraw() {
        // This is a hack to force the CollectionViewSlantedLayout to do an
        // animated redraw
        itemSize += 1
        collectionView?.performBatchUpdates({}, completion: {_ in })
    }
}
