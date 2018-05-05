//
//  FaceBalls.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/5/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import SpriteKit

class FaceBalls: Animation {
    var title: String = "Face Balls"

    func animate(view: UIView, completion: @escaping ()->()) {
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
}
