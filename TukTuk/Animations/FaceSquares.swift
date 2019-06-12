//
//  FaceSquares.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/5/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import SpriteKit

class FaceSquares: Animation {
    var title: String = "Face Squares"

    required init() {
    }

    func animate(view: UIView, completion: @escaping ()->()) {
        AudioPlayer.instance.play(Sounds.Welcome.audio)

        let images = (1...12).map { "FaceSquares_\($0)" }

        let skView = SKView(frame: view.frame)
        skView.allowsTransparency = true
        view.addSubview(skView)

        let scene = SKScene(size: CGSize(width: view.frame.width, height: view.frame.height))
        scene.backgroundColor = .clear
        skView.presentScene(scene)

        images.shuffled().enumerated().forEach {
            (i, imageName) in

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 * Double(i)) {
                let side: Int = [80, 100, 120].randomElement()!
                let face = SKShapeNode(rectOf: CGSize(width: side, height: side), cornerRadius: 20)
                face.lineWidth = 1
                face.fillColor = .white
                face.fillTexture = SKTexture(imageNamed: imageName)
                let texture = skView.texture(from: face)

                let sprite: SKSpriteNode = SKSpriteNode(texture: texture)
                sprite.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: side, height: side))
                sprite.physicsBody?.usesPreciseCollisionDetection = true
                sprite.physicsBody?.restitution = CGFloat(0.9 + [-0.05, 0, 0.05].randomElement()!)
                sprite.position = CGPoint(x: scene.frame.width * 0.4 + CGFloat([-40, -20, 0, 20, 40].randomElement()!), y: scene.frame.height)
                sprite.zRotation = CGFloat(45.0 * [-1, 1].randomElement()!)
                scene.addChild(sprite)
            }
        }

        var splinePoints = [CGPoint(x: 0, y: scene.frame.height),
                            CGPoint(x: scene.frame.width * 0.1, y: 100),
                            CGPoint(x: scene.frame.width * 0.9, y: 100),
                            CGPoint(x: scene.frame.width, y: scene.frame.height)]
        let ground = SKShapeNode(splinePoints: &splinePoints,
                                 count: splinePoints.count)
        ground.lineWidth = 3
        ground.physicsBody = SKPhysicsBody(edgeChainFrom: ground.path!)
        ground.physicsBody?.restitution = 0.9
        ground.physicsBody?.isDynamic = false
        scene.addChild(ground)

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            skView.removeFromSuperview()
            completion()
        }
    }
}
