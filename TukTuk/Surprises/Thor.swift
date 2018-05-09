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
    func play(on view: UIView)
}

class Thor: Surprise {
    func play(on view: UIView) {
        let skView = SKView(frame: view.frame)
        skView.allowsTransparency = true
        view.addSubview(skView)

        let thorScene = ThorScene(size: view.frame.size)
        skView.presentScene(thorScene)
    }
}

class ThorScene: SKScene, SKPhysicsContactDelegate {
    var thor: SKSpriteNode!
    var hammer: SKSpriteNode!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(size: CGSize) {
        super.init(size: size)
        
        let thorTexture = SKTexture(imageNamed: "thor_summoning_hammer")
        thor = SKSpriteNode(texture: thorTexture, size: CGSize(width: thorTexture.size().width * 0.5, height: thorTexture.size().height * 0.5))

        let hammerTexture = SKTexture(imageNamed: "thor_hammer")
        hammer = SKSpriteNode(texture: hammerTexture, size: CGSize(width: hammerTexture.size().width * 0.75, height: hammerTexture.size().height * 0.75))

        backgroundColor = .clear

    }

    override func didMove(to view: UIView) {
        let width = view.frame.width
        let height = view.frame.height

        var points = [CGPoint(x: 0, y: height * 0.5),
                      CGPoint(x: 0, y: 10),
                      CGPoint(x: width, y: 10),
                      CGPoint(x: width, y: height * 0.5)]
        let ground = SKShapeNode(points: &points, count: points.count)
        ground.lineWidth = 3
        ground.physicsBody = SKPhysicsBody(edgeChainFrom: ground.path!)
        ground.physicsBody?.restitution = 0
        ground.physicsBody?.isDynamic = false
        addChild(ground)

        hammer.position = CGPoint(x: width - hammer.size.width - 10, y: height)
        hammer.physicsBody = SKPhysicsBody(rectangleOf: hammer.size)
        hammer.physicsBody?.restitution = 0
        hammer.zRotation = 0
        addChild(hammer)

        thor.position = CGPoint(x: -100, y: height - 100)
        thor.physicsBody?.isDynamic = false
        addChild(thor)

        thor.run(SKAction.move(to: CGPoint(x: width * 0.25, y: height * 0.75), duration: 5.0))
    }
}
