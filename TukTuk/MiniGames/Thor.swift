//
//  Thor.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/9/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

extension Media {
    static let Thor = Media("Thor")
}

final class Thor: MiniGame {
    var title = "Thor lost his hammer!"
    var uivc: UIViewController = UIVC()

    enum Collisions: UInt32 {
        case floor  = 1
        case hammer = 2
        case thor   = 4
    }

    class UIVC: UIViewController {
        override func viewDidAppear(_ animated: Bool) {
            let effect = UIBlurEffect(style: .light)
            let effectView = UIVisualEffectView(effect: effect)
            effectView.frame = view.frame
            view.addSubview(effectView)

            let skView = SKView(frame: view.frame)
            skView.allowsTransparency = true
            effectView.contentView.addSubview(skView)

            let scene = Scene(size: view.frame.size)
            skView.presentScene(scene)

            scene.completion = {
                self.dismiss(animated: true)
            }
        }
    }

    class ThorSKSpriteNode: SKSpriteNode {
        var thorScene: Scene {
            return scene as! Scene
        }
    }

    class Hammer: ThorSKSpriteNode {
        var touchCount = 0

        init() {
            let texture = SKTexture(image: #imageLiteral(resourceName: "Thor_Hammer"))
            super.init(texture: texture, color: .clear, size: texture.size())
            physicsBody = SKPhysicsBody(rectangleOf: size)
            physicsBody?.restitution = 0
            physicsBody?.categoryBitMask = Collisions.hammer.rawValue
            physicsBody?.contactTestBitMask = Collisions.floor.rawValue

            setScale(0.5)
            zRotation = -0.3
            run(SKAction.rotate(byAngle: -0.5, duration: 1.0))
            isUserInteractionEnabled = true
        }

        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            touchCount += 1

            switch touchCount {
            case 1...2:
                run(SKAction.rotate(toAngle: -0.2, duration: 0.1))
                thud()

            case 3:
                thorScene.thor.flyIn()

            default:
                break
            }
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard touchCount > 3, let view = scene?.view else {
                return
            }

            // Y-axis is inverted so we have to translate the position on drag
            for touch in touches {
                let touchLocation = touch.location(in: view)
                position = CGPoint(x: touchLocation.x, y: view.frame.height - touchLocation.y)

                let distance = thorScene.thor.handPosition.distance(to: position)

                // Rotate the hammer the closer the hammer moves to Thor's hand so that when
                // it gets to his hand it's in roughly the right orientation, which is about 1.8 radians
                zRotation = (440 - distance) / 400 * 1.1

                if distance < 40 {
                    thorScene.thor.grabHammer()
                    removeFromParent()
                }
            }
        }

        func thud() {
            Sound.Thor_HammerLandingThud.play()
        }
    }

    class Thor: ThorSKSpriteNode {
        var touchCount = 0

        var handPosition: CGPoint {
            // Approximate the top left quadrant
            return CGPoint(x: position.x - size.width * 0.3, y: position.y + size.width * 0.6)
        }

        init() {
            let texture = SKTexture(image: #imageLiteral(resourceName: "Thor_SummoningHammer"))
            super.init(texture: texture, color: .clear, size: texture.size())
            physicsBody?.isDynamic = false
            physicsBody?.categoryBitMask = Collisions.thor.rawValue

            setScale(0.5)
            isUserInteractionEnabled = true
        }

        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }

        func flyIn() {
            guard let scene = scene else { return }

            run(SKAction.move(to: CGPoint(x: 120, y: scene.frame.height - size.height - 20), duration: 1.0))
            Sound.Thor_ILostMyHammer.play()
        }

        func grabHammer() {
            texture = SKTexture(image: #imageLiteral(resourceName: "Thor_GrabHammer"))
            guard let texture = texture, let frame = scene?.frame else {
                return
            }

            size = CGSize(width: texture.size().width * 0.5, height: texture.size().height * 0.5)

            Sound.Thor_IAmTheGodOfThunder.play()

            run(SKAction.group([
                    SKAction.move(to: CGPoint(x: frame.width * 0.1, y: frame.height * 0.5), duration: 2.0),
                    SKAction.scale(by: 1.5, duration: 4.0)])) {
                self.flyAway()
            }
        }

        func flyAway() {
            texture = SKTexture(image: #imageLiteral(resourceName: "Thor_FlyAway"))
            guard let texture = texture else {
                return
            }

            size = CGSize(width: texture.size().width * 0.75, height: texture.size().height * 0.75)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.run(SKAction.moveTo(x: self.frame.width * 2.0, duration: 1.0 )) {
                    self.thorScene.finish()
                }
            }

            Sound.Thor_ThankYou.play()
        }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            Sound.Thor_IReallyWishIHadMyHammer.play()
        }
    }

    class Scene: SKScene, SKPhysicsContactDelegate {
        var thor = Thor()
        var hammer = Hammer()
        var completion: () -> () = {}

        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }

        override init(size: CGSize) {
            super.init(size: size)
            backgroundColor = .clear
        }

        override func didMove(to view: UIView) {
            let width = view.frame.width
            let height = view.frame.height

            var points = [CGPoint(x: 0, y: height),
                          CGPoint(x: 0, y: 30),
                          CGPoint(x: width, y: 30),
                          CGPoint(x: width, y: height)]
            let border = SKShapeNode(points: &points, count: points.count)
            border.lineWidth = 1
            border.strokeColor = .clear
            border.physicsBody = SKPhysicsBody(edgeChainFrom: border.path!)
            border.physicsBody?.categoryBitMask = Collisions.floor.rawValue
            border.physicsBody?.restitution = 0
            border.physicsBody?.isDynamic = false
            addChild(border)

            thor.position = CGPoint(x: -100, y: height+100)
            addChild(thor)

            hammer.position = CGPoint(x: width * 0.5, y: height + 100)
            addChild(hammer)

            physicsWorld.contactDelegate = self
            physicsWorld.gravity = CGVector(dx: 0, dy: -2)

            Sound.Thor_HammerFallingWhistle.play()
        }

        func finish() {
            completion()
        }

        func didBegin(_ contact: SKPhysicsContact) {
            if contact.bodyA.node == hammer || contact.bodyB.node == hammer {
                hammer.thud()
            }
        }
    }
}
