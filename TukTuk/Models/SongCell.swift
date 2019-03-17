//
//  SongCell.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 3/16/19.
//  Copyright © 2019 Menalto. All rights reserved.
//

import Foundation
import CollectionViewSlantedLayout
import QuartzCore


class SongCell: CollectionViewSlantedCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var title: UILabel!
    private var gradient = CAGradientLayer()

    override func awakeFromNib() {
        super.awakeFromNib()

        if let backgroundView = backgroundView {
            gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
            gradient.locations = [0.0, 1.0]
            gradient.frame = backgroundView.bounds
            backgroundView.layer.addSublayer(gradient)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let backgroundView = backgroundView {
            gradient.frame = backgroundView.bounds
        }
    }

    var image: UIImage = UIImage() {
        didSet {
            imageView.image = image
        }
    }

    var imageHeight: CGFloat {
        return (imageView?.image?.size.height) ?? 0.0
    }

    var imageWidth: CGFloat {
        return (imageView?.image?.size.width) ?? 0.0
    }

    func offset(_ offset: CGPoint) {
        imageView.frame = imageView.bounds.offsetBy(dx: offset.x, dy: offset.y)
    }
}
