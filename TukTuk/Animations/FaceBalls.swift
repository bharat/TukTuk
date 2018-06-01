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
    static var title: String = "Face Balls"

    required init() {
    }

    func animate(view: UIView, completion: @escaping ()->()) {
        AudioPlayer.play(Catalog.sound("Welcome.mp3"))

        let images = (1...8).map { "FaceBalls_\($0)" }

        let skView = SKView(frame: view.frame)
        skView.allowsTransparency = true
        view.addSubview(skView)

        let scene = SKScene(size: CGSize(width: view.frame.width, height: view.frame.height))
        scene.backgroundColor = .clear
        skView.presentScene(scene)

        images.shuffled().enumerated().forEach {
            (i, imageName) in

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 * Double(i)) {
                let radius: CGFloat = 30 + [10, 20, 30].random!
                let face = SKShapeNode(circleOfRadius: radius)
                face.lineWidth = 1
                face.fillColor = .white
                face.fillTexture = SKTexture(imageNamed: imageName)
                let texture = skView.texture(from: face)

                let sprite: SKSpriteNode = SKSpriteNode(texture: texture)
                sprite.physicsBody = SKPhysicsBody(circleOfRadius: radius)
                sprite.physicsBody?.usesPreciseCollisionDetection = true
                sprite.physicsBody?.restitution = 0.9 + [-0.05, 0, 0.05].random!
                sprite.position = CGPoint(x: scene.frame.width * 0.4 + [-40, -20, 0, 20, 40].random!, y: scene.frame.height)
                sprite.zRotation = 45.0 * [-1, 1].random!
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
