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
    enum Collisions: UInt32 {
        case floor  = 1
        case hammer = 2
        case thor   = 4
    }

    func play(on view: UIView) {
        let effect = UIBlurEffect(style: .light)
        let effectView = UIVisualEffectView(effect: effect)
        effectView.frame = view.frame
        view.addSubview(effectView)

        let skView = SKView(frame: view.frame)
        skView.allowsTransparency = true
        effectView.contentView.addSubview(skView)

        let scene = Scene(size: view.frame.size)
        skView.presentScene(scene)
    }

    class Hammer: SKSpriteNode {
        var touchCount = 0

        var thorScene: Scene {
            return scene as! Scene
        }

        init() {
            let texture = SKTexture(imageNamed: "thor_hammer")
            super.init(texture: texture, color: .clear, size: texture.size())
            physicsBody = SKPhysicsBody(rectangleOf: size)
            physicsBody?.restitution = 0
            physicsBody?.categoryBitMask = Collisions.hammer.rawValue
            physicsBody?.contactTestBitMask = Collisions.floor.rawValue

            setScale(0.5)
            zRotation = -0.5
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
            guard touchCount > 3 else { return }
            guard scene != nil else { return }

            // Y-axis is inverted so we have to translate the position on drag
            for touch in touches {
                let touchLocation = touch.location(in: scene!.view!)
                position = CGPoint(x: touchLocation.x, y: scene!.view!.frame.height - touchLocation.y)

                zRotation += 0.1

                if thorScene.thor.handPosition.distance(to: position) < 20 {
                    thorScene.thor.grabHammer()
                    removeFromParent()
                }
            }
        }

        func thud() {
            Audio.instance.stop()
            Audio.instance.play(Bundle.main.url(forAuxiliaryExecutable: "Sounds/ThorHammerLandingThud.mp3")!)
        }
    }

    class Thor: SKSpriteNode {
        var touchCount = 0

        var thorScene: Scene {
            return scene as! Scene
        }

        var handPosition: CGPoint {
            // Approximate the top left quadrant
            return CGPoint(x: position.x - size.width * 0.3, y: position.y + size.width * 0.6)
        }

        init() {
            let texture = SKTexture(imageNamed: "thor_summoning_hammer")
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
            run(SKAction.move(to: CGPoint(x: 120, y: scene!.frame.height - size.height - 20), duration: 1.0))
            Audio.instance.stop()
            Audio.instance.play(Bundle.main.url(forAuxiliaryExecutable: "Sounds/ThorILostMyHammer.mp3")!)
        }

        func grabHammer() {
            texture = SKTexture(imageNamed: "thor_grab_hammer")
            size = CGSize(width: texture!.size().width * 0.5, height: texture!.size().height * 0.5)

            Audio.instance.stop()
            Audio.instance.play(Bundle.main.url(forAuxiliaryExecutable: "Sounds/ThorIAmTheGodOfThunder.mp3")!)

            run(SKAction.group([
                    SKAction.move(to: CGPoint(x: scene!.frame.width * 0.5, y: scene!.frame.height * 0.5), duration: 2.0),
                    SKAction.scale(by: 1.5, duration: 4.0)])) {
                self.flyAway()
            }
        }

        func flyAway() {
            texture = SKTexture(imageNamed: "thor_fly_away")
            size = CGSize(width: texture!.size().width * 0.75, height: texture!.size().height * 0.75)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.run(SKAction.moveTo(x: self.scene!.frame.width * 2.0, duration: 0.5))
            }

            Audio.instance.stop()
            Audio.instance.play(Bundle.main.url(forAuxiliaryExecutable: "Sounds/ThorThankYou.mp3")!)
        }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            Audio.instance.stop()
            Audio.instance.play(Bundle.main.url(forAuxiliaryExecutable: "Sounds/ThorIReallyWishIHadMyHammer.mp3")!)
        }
    }

    class Scene: SKScene, SKPhysicsContactDelegate {
        var thor = Thor()
        var hammer = Hammer()

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

            let ground = SKShapeNode(rect: CGRect(x: 0, y: 0, width: width, height: 1))
            ground.lineWidth = 1
            ground.strokeColor = .clear
            ground.physicsBody = SKPhysicsBody(edgeChainFrom: ground.path!)
            ground.physicsBody?.categoryBitMask = Collisions.floor.rawValue
            ground.physicsBody?.restitution = 0
            ground.physicsBody?.isDynamic = false
            addChild(ground)

            thor.position = CGPoint(x: -100, y: height+100)
            addChild(thor)

            hammer.position = CGPoint(x: width - hammer.size.width - 10, y: height + 100)
            addChild(hammer)

            physicsWorld.contactDelegate = self
            physicsWorld.gravity = CGVector(dx: 0, dy: -1)

            Audio.instance.play(Bundle.main.url(forAuxiliaryExecutable: "Sounds/ThorHammerFallingWhistle.mp3")!)
        }

        func didEnd(_ contact: SKPhysicsContact) {
        }

        func didBegin(_ contact: SKPhysicsContact) {
            if contact.bodyA.node == hammer || contact.bodyB.node == hammer {
                hammer.thud()
            }
        }
    }
}
