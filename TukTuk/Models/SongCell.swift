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

        title.layer.shadowColor = UIColor.black.cgColor
        title.layer.shadowRadius = 3.0
        title.layer.shadowOpacity = 0.8
        title.layer.shadowOffset = .zero
        title.layer.masksToBounds = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let backgroundView = backgroundView {
            backgroundView.frame = contentView.bounds
            gradient.frame = backgroundView.bounds

            if isSelected {
                imageView.frame = backgroundView.bounds
            } else {
                // pad the image frame so that we don't see edges in the parallax view
                imageView.frame = CGRect(x: 0, y: 0, width: backgroundView.bounds.width, height: backgroundView.bounds.height + 300)
            }
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

    var slantingAngle: CGFloat = 0.0 {
        didSet {
            if slantingAngle != oldValue {
                title.transform = CGAffineTransform(rotationAngle: slantingAngle)
            }
        }
    }
}
