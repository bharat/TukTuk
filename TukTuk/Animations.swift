//
//  Animations.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 11/21/17.
//  Copyright © 2017 Menalto. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit
    
typealias Animation = (UIView, @escaping()->()) -> ()

class Animations {
    static func random(view: UIView, completion: @escaping ()->()) {
        let animations: [Animation] = [
            Animations.hinge,
            Animations.rollAway,
            Animations.wordPop,
            Animations.faceBalls
        ]
        let animation = animations[Int(arc4random_uniform(UInt32(animations.count)))]
        animation(view) {
            completion()
        }
    }

    static func faceBalls(view: UIView, completion: @escaping ()->()) {
        let images = (1...8).map { i in "Images/Remy_\(i).png" }

        let skView = SKView(frame: view.frame)
        skView.allowsTransparency = true
        view.addSubview(skView)

        let scene = SKScene(size: CGSize(width: view.frame.width, height: view.frame.height))
        scene.backgroundColor = .clear
        skView.presentScene(scene)

        images.enumerated().forEach {
            (i, imageName) in

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 * Double(i)) {
                let face = SKShapeNode(circleOfRadius: 50)
                face.lineWidth = 1
                face.fillColor = .white
                face.fillTexture = SKTexture(imageNamed: imageName)
                let texture = skView.texture(from: face)

                let sprite: SKSpriteNode = SKSpriteNode(texture: texture)
                sprite.physicsBody = SKPhysicsBody(circleOfRadius: 50)
                sprite.physicsBody?.usesPreciseCollisionDetection = true
                sprite.physicsBody?.restitution = 0.9
                sprite.position = CGPoint(x: scene.frame.width * 0.4 + (CGFloat(i) * 20.0), y: scene.frame.height)
                sprite.zRotation = 45.0
                scene.addChild(sprite)
            }
        }

        var splinePoints = [CGPoint(x: 0, y: scene.frame.height * 0.75),
                            CGPoint(x: scene.frame.width * 0.1, y: 70),
                            CGPoint(x: scene.frame.width * 0.9, y: 70),
                            CGPoint(x: scene.frame.width, y: scene.frame.height * 0.75)]
        let ground = SKShapeNode(splinePoints: &splinePoints,
                                 count: splinePoints.count)
        ground.lineWidth = 3
        ground.physicsBody = SKPhysicsBody(edgeChainFrom: ground.path!)
        ground.physicsBody?.restitution = 0.9
        ground.physicsBody?.isDynamic = false
        scene.addChild(ground)

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            UIView.animate(withDuration: 1.0, animations: {
                view.frame.origin.y = view.superview!.frame.height
                view.alpha = 0
            }, completion: {
                (_) in
                view.removeFromSuperview()
            })
        }
    }

    static func wordPop(view: UIView, completion: @escaping ()->()) {
        let cadence: [(words: String, duration: CFTimeInterval)] = [
            ("Hi,\nRemy!",                           1.0),
            ("Welcome\nto\nTukTuk!",                 1.0),
            ("You can\nlisten to some\nmusic here!", 2.0),
            ("Woohoooooo!",                          1.0)
        ]
        var labels: [UILabel] = []

        // Create and place labels. We start with a big label and scale it down so that
        // when we scale it back up again it doesn't have jagged edges.
        cadence.forEach {
            (text, _) in
            let label = UILabel()
            label.numberOfLines = text.filter { $0 == "\n" }.count + 1
            label.textAlignment = .center
            label.textColor = .white
            label.text = text
            label.font = .boldSystemFont(ofSize: 70)
            label.sizeToFit()
            label.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
            label.alpha = 0
            label.center = view.center
            view.addSubview(label)
            labels.append(label)
        }

        var anim = UIView.animateAndChain(withDuration: 0, delay: 0, options: .curveEaseOut, animations: {}, completion: nil)

        // Let the text sit for a bit, then animate it away by having it grow and change color while fading out.
        let colors: [UIColor] = [.red, .green, .blue, .yellow, .gray]
        cadence.enumerated().forEach {
            (i, tuple) in
            let label = labels[i]
            anim = anim.animate(withDuration: 0, animations: {
                label.alpha = 1.0
            })
            .animate(withDuration: 0.5, delay: tuple.duration - 0.5, options: .curveEaseIn, animations: {
                label.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                label.alpha = 0.2
                label.textColor = colors[Int(arc4random_uniform(UInt32(colors.count)))]
            }, completion: {
                (_) in
                label.isHidden = true
                label.removeFromSuperview()
            })
        }

        anim.animate(withDuration: 1.0, animations: {
            view.frame.origin.y = view.superview!.frame.height
            view.alpha = 0
        }, completion: {
            (_) in
            view.removeFromSuperview()
        })
    }

    static func rollAway(view: UIView, completion: @escaping ()->()) {
        UIView.animateAndChain(withDuration: 3.5, delay: 0.0, options: [ .curveEaseIn ], animations: {
            // Transform into a circle in the left center
            view.layer.borderWidth = 5.0
            view.layer.frame = CGRect(x: 0, y: view.superview!.frame.height / 2 - 100, width: 200, height: 200)
            view.layer.cornerRadius = 100

            // While doing one full rotation
            view.layer.transform = CATransform3DMakeRotation(CGFloat.pi, 0, 0, 1)

            // Then spin and accelerate
        }, completion: nil)
        .animate(withDuration: 0.5, delay: 0.0, options: [ .curveLinear ], animations: {
            view.layer.transform = CATransform3DMakeRotation(CGFloat.pi * 2, 0, 0, 1)
        }, completion: nil)
        .animate(withDuration: 0.4, delay: 0.0, options: [ .curveLinear ], animations: {
            view.layer.transform = CATransform3DMakeRotation(CGFloat.pi, 0, 0, 1)
        }, completion: nil)
        .animate(withDuration: 0.3, delay: 0.0, options: [ .curveLinear ], animations: {
            view.layer.transform = CATransform3DMakeRotation(CGFloat.pi * 2, 0, 0, 1)
        }) { _ in
            // Then zoom off to the right
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                completion()
            }
            let spin = CABasicAnimation(keyPath: "transform.rotation")
            spin.fromValue = 0.0
            spin.toValue = CGFloat.pi * 2
            spin.isRemovedOnCompletion = false
            spin.repeatDuration = 0.5
            spin.duration = 0.3
            view.layer.add(spin, forKey: nil)

            let zoom = CABasicAnimation(keyPath: "position.x")
            zoom.fromValue = 100
            zoom.duration = 0.5
            zoom.toValue = view.superview!.frame.width + 100
            zoom.isRemovedOnCompletion = false
            zoom.fillMode = kCAFillModeForwards
            view.layer.add(zoom, forKey: nil)
            CATransaction.commit()
        }
    }

    static func hinge(view: UIView, completion: @escaping ()->()) {
        // Animate away the welcome image. Shrink it down to 40% of its size in the
        // center of the screen, then do a "hinge" animation where the top right corner
        // releases and it falls down around the top left corner, then the whole image
        // falls off the bottom of the page.
        let easeInOut = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        let easeLinear = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                completion()
            }

            // Move the anchor point to the top left, so that the rotation effect looks like
            // it's falling down on the right side. This will move the overlay, so make sure
            // that we recenter it.
            view.layer.anchorPoint = CGPoint(x: 0, y: 0)
            view.center = CGPoint(x: view.center.x * 0.6, y: view.center.y * 0.6)

            let second = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            second.fillMode = kCAFillModeForwards
            second.isRemovedOnCompletion = false
            second.beginTime = 0.1
            second.duration = 3.5

            let t = Float.pi / 7
            let k = Float.pi / 9
            second.values = [0.0] +
                [2.56, -1.28, 0.64, -0.32, 0.16, -0.08, 0.04, -0.02, 0.01].map { t + $0 * k } +
                [t]
            second.keyTimes = (0...10).map { (Double($0) * 0.1) as NSNumber }
            second.timingFunctions = [CAMediaTimingFunction](repeating: easeInOut, count: 10)

            let third = CAKeyframeAnimation(keyPath: "position.y")
            third.fillMode = kCAFillModeForwards
            third.isRemovedOnCompletion = false
            third.beginTime = second.beginTime + second.duration
            third.duration = 1.0
            third.values = [view.frame.origin.y, view.superview!.frame.height * 2]
            third.keyTimes = [0.0, 1.0]
            third.timingFunctions = [easeLinear]

            let group = CAAnimationGroup()
            group.duration = third.beginTime + third.duration
            group.fillMode = kCAFillModeForwards
            group.isRemovedOnCompletion = false
            group.animations = [second, third]
            view.layer.add(group, forKey:nil)
            CATransaction.commit()
        }

        let first = CAKeyframeAnimation(keyPath: "transform.scale")
        first.fillMode = kCAFillModeForwards
        first.isRemovedOnCompletion = false
        first.beginTime = 0.0
        first.duration = 1.0
        first.values =   [1.0, 0.35, 0.425, 0.3875, 0.40625, 0.3969, 0.4]
        first.keyTimes = [0.0, 0.5,  0.6,   0.7,    0.8,     0.9,    1.0]
        first.timingFunctions = [easeInOut, easeInOut, easeInOut, easeInOut, easeInOut]
        view.layer.add(first, forKey: nil)
        CATransaction.commit()
    }
}
