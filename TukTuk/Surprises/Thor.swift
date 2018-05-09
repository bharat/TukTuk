//
//  Thor.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/9/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import SpriteKit

protocol Surprise {
    func play(view: UIView)
}

class Thor: Surprise {
    func play(view: UIView) {
        let skView = SKView(frame: view.frame)
        skView.allowsTransparency = true
        view.addSubview(skView)

        let width = view.frame.width
        let height = view.frame.height

        let scene = SKScene(size: CGSize(width: width, height: height))
        scene.backgroundColor = .clear
        skView.presentScene(scene)

        var points = [CGPoint(x: 0, y: height * 0.5),
                      CGPoint(x: 0, y: 10),
                      CGPoint(x: width, y: 10),
                      CGPoint(x: width, y: height * 0.5)]
        let ground = SKShapeNode(points: &points, count: points.count)
        ground.lineWidth = 3
        ground.physicsBody = SKPhysicsBody(edgeChainFrom: ground.path!)
        ground.physicsBody?.restitution = 0
        ground.physicsBody?.isDynamic = false
        scene.addChild(ground)

        let hammerTexture = SKTexture(imageNamed: "thor_hammer")
        let hammer = SKSpriteNode(texture: hammerTexture, size: CGSize(width: hammerTexture.size().width * 0.75, height: hammerTexture.size().height * 0.75))
        hammer.position = CGPoint(x: width - hammer.size.width - 10, y: height)
        hammer.physicsBody = SKPhysicsBody(rectangleOf: hammer.size)
        hammer.physicsBody?.restitution = 0
        hammer.zRotation = 0
        scene.addChild(hammer)

        let thorTexture = SKTexture(imageNamed: "thor_summoning_hammer")
        let thor = SKSpriteNode(texture: thorTexture, size: CGSize(width: thorTexture.size().width * 0.5, height: thorTexture.size().height * 0.5))
        thor.position = CGPoint(x: -100, y: height - 100)
        thor.physicsBody?.isDynamic = false
        scene.addChild(thor)

        thor.run(SKAction.move(to: CGPoint(x: width * 0.25, y: height * 0.75), duration: 5.0))
    }
}
