//
//  Labyrinth.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 8/23/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit
import CoreMotion

final class Labyrinth: MiniGame {
    var title = "Labyrinth"
    var uivc: UIViewController = UIVC()

    enum Collisions: UInt32 {
        case wall   = 1
        case marble = 2
        case target = 4
    }

    func preloadableAssets() -> [URL] {
        return []
    }

    class UIVC: UIViewController {
        var scene: Scene?

        override func viewDidAppear(_ animated: Bool) {
            let effect = UIBlurEffect(style: .light)
            let effectView = UIVisualEffectView(effect: effect)
            effectView.frame = view.frame
            view.addSubview(effectView)

            let skView = SKView(frame: view.frame.insetBy(dx: 8, dy: 20))
            skView.allowsTransparency = true
            effectView.contentView.addSubview(skView)

            scene = Scene(size: view.frame.insetBy(dx: 8, dy: 20).size)
            scene?.complexity = 6
            scene?.completion = {
                self.dismiss(animated: true)
            }
            skView.presentScene(scene!)
        }

        override func viewWillDisappear(_ animated: Bool) {
            scene?.removeFromParent()
            scene = nil
        }
    }

    class Translator {
        let scaleX: CGFloat
        let scaleY: CGFloat

        init(frame: CGRect, rows: Int, cols: Int) {
            scaleX = frame.width / CGFloat(cols)
            scaleY = frame.height / CGFloat(rows)
        }

        func mazePosition(from pos: CGPoint) -> Maze.Position {
            return Maze.Position(row: Int(floor(pos.y / scaleY)), col: Int(floor(pos.x / scaleX)))
        }

        func nodePosition(from pos: Maze.Position) -> CGPoint {
            return CGPoint(x: CGFloat(pos.col + 1) * scaleX - 0.5 * scaleX,
                           y: CGFloat(pos.row + 1) * scaleY - 0.5 * scaleY)
        }
    }

    class RoundSprite {
        var node: SKSpriteNode
        var view: SKView
        var translator: Translator

        init(imageName: String, view: SKView, radius: CGFloat, translator: Translator) {
            self.view = view
            self.translator = translator

            let textureNode = SKShapeNode(circleOfRadius: radius)
            textureNode.lineWidth = 1
            textureNode.fillColor = .white
            textureNode.fillTexture = SKTexture(imageNamed: imageName)
            let marbleTexture = view.texture(from: textureNode)

            node = SKSpriteNode(texture: marbleTexture)
            node.physicsBody = SKPhysicsBody(circleOfRadius: radius)
            node.physicsBody?.usesPreciseCollisionDetection = true
            node.physicsBody?.restitution = 0.2
            node.physicsBody?.contactTestBitMask = Collisions.wall.rawValue
        }

        var mazePosition: Maze.Position {
            get {
                return translator.mazePosition(from: node.position)
            }
            set {
                node.position = translator.nodePosition(from: newValue)
            }
        }
    }

    class Marble: RoundSprite {
        override init(imageName: String, view: SKView, radius: CGFloat, translator: Translator) {
            super.init(imageName: imageName, view: view, radius: radius, translator: translator)
            node.physicsBody?.categoryBitMask = Collisions.marble.rawValue
            node.physicsBody?.contactTestBitMask |= Collisions.target.rawValue
        }
    }

    class Target: RoundSprite {
        override init(imageName: String, view: SKView, radius: CGFloat, translator: Translator) {
            super.init(imageName: imageName, view: view, radius: radius, translator: translator)
            node.physicsBody?.categoryBitMask = Collisions.target.rawValue
            node.physicsBody?.contactTestBitMask |= Collisions.marble.rawValue
            node.physicsBody?.isDynamic = false
            node.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1.0)))
        }
    }

    class Wall {
        var node: SKShapeNode
        var direction: Maze.Direction
        var translator: Translator

        init(direction: Maze.Direction, translator: Translator) {
            self.direction = direction
            self.translator = translator

            node = SKShapeNode(rect: {
                switch direction {
                case .up, .down:
                    return CGRect(x: 0, y: 0, width: translator.scaleX, height: 0)
                case .left, .right:
                    return CGRect(x: 0, y: 0, width: 0, height: translator.scaleY)
                }
            }())

            node.lineWidth = 4
            node.lineCap = .round
            node.strokeColor = .white
            node.physicsBody = SKPhysicsBody(edgeChainFrom: node.path!)
            node.physicsBody?.categoryBitMask = Collisions.wall.rawValue
            node.physicsBody?.restitution = 0.2
            node.physicsBody?.isDynamic = false
        }

        func moveTo(pos: Maze.Position) {
            node.position = translator.nodePosition(from: pos)
            switch direction {
            case .up:
                node.position.y += translator.scaleY
            case .right:
                node.position.x += translator.scaleX
            default:
                break
            }
        }
    }

    class Solution {
        var node: SKShapeNode
        var translator: Translator
        let pattern: [CGFloat] = [3.0, 2.0]

        init(translator: Translator) {
            self.translator = translator

            let bezierPath = UIBezierPath()
            node = SKShapeNode(path: bezierPath.cgPath.copy(dashingWithPhase: 2, lengths: pattern))
            node.strokeColor = .clear
            node.lineWidth = 1
        }

        func show(maze: Maze, src: RoundSprite, dst: RoundSprite) {
            let path = maze.solve(from: src.mazePosition, to: dst.mazePosition)!
            let points = path.map { pos in translator.nodePosition(from: pos) }
            let bezierPath = UIBezierPath()
            bezierPath.move(to: points[0])
            points.dropFirst().forEach { point in
                bezierPath.addLine(to: point)
            }
            node.strokeColor = .green
            node.path = bezierPath.cgPath.copy(dashingWithPhase: 2, lengths: pattern)
            node.run(SKAction.fadeOut(withDuration: 2.0))
        }
    }

    class Scene: SKScene, SKPhysicsContactDelegate {
        let motionManager = CMMotionManager()
        var completion: () -> () = { }
        var complexity: Int = 2
        var marble: Marble!
        var target: Target!
        var maze: Maze!
        var solution: Solution!
        var translator: Translator!

        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }

        override init(size: CGSize) {
            super.init(size: size)
            backgroundColor = .clear
        }

        override func didMove(to view: UIView) {
            let border = SKShapeNode(rect: frame)
            border.lineWidth = 4
            border.strokeColor = .white
            border.physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
            border.physicsBody?.categoryBitMask = Collisions.wall.rawValue
            border.physicsBody?.restitution = 0.2
            border.physicsBody?.isDynamic = false
            addChild(border)

            let rows = Int(CGFloat(complexity) * (frame.height / frame.width))
            let cols = complexity
            maze = Maze(cols: cols, rows: rows)

            translator = Translator(frame: frame, rows: rows, cols: cols)

            for (row, cols) in maze.maze.enumerated() {
                for (col, bits) in cols.enumerated() {
                    Maze.Direction.allCases.forEach { direction in
                        if direction.rawValue & bits == 0 {
                            let wall = Wall(direction: direction, translator: translator)
                            wall.moveTo(pos: Maze.Position(row: row, col: col))
                            addChild(wall.node)
                        }
                    }
                }
            }

            marble = Marble(imageName: "Labyrinth_Marble", view: self.view!, radius: 0.4, translator: translator)
            marble.mazePosition = Maze.Position(row: rows - 1, col: cols - 1) // top right
            addChild(marble.node)

            target = Target(imageName: "Labyrinth_Target", view: self.view!, radius: 0.4, translator: translator)
            target.mazePosition = Maze.Position(row: 0, col: 0) // bottom left
            addChild(target.node)

            physicsWorld.contactDelegate = self
            physicsWorld.gravity = CGVector(dx: 0, dy: 0)

            if motionManager.isAccelerometerAvailable {
                motionManager.startAccelerometerUpdates()
            }

            solution = Solution(translator: translator)
            addChild(solution.node)
        }

        func done() {
            motionManager.startAccelerometerUpdates()
            completion()
        }

        override func update(_ currentTime: TimeInterval) {
            super.update(currentTime)

            if let data = motionManager.accelerometerData {
                physicsWorld.gravity = CGVector(dx: data.acceleration.x * 5.0, dy: data.acceleration.y * 5.0)
            }

            solution.show(maze: maze, src: marble, dst: target)
        }

        func didBegin(_ contact: SKPhysicsContact) {
            switch contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask {
            case Collisions.marble.rawValue | Collisions.target.rawValue:
                done()
            case Collisions.marble.rawValue | Collisions.wall.rawValue:
                break // play a sound
            default:
                break
            }
        }
    }
}

// Enable arrow keys to simulate motion in the simulator
extension Labyrinth.UIVC {
    override var keyCommands: [UIKeyCommand]? {
        get {
            return [
                UIKeyCommand.inputUpArrow,
                UIKeyCommand.inputDownArrow,
                UIKeyCommand.inputLeftArrow,
                UIKeyCommand.inputRightArrow,
                " "
            ].map {
                UIKeyCommand(input: $0, modifierFlags: [], action: #selector(handleKey(sender:)))
            }
        }
    }

    @objc func handleKey(sender: UIKeyCommand) {
        var dx: Int = 0
        var dy: Int = 0

        switch sender.input {
        case UIKeyCommand.inputUpArrow:             dy =  5
        case UIKeyCommand.inputDownArrow:           dy = -5
        case UIKeyCommand.inputLeftArrow:           dx = -5
        case UIKeyCommand.inputRightArrow:          dx =  5
        default:
            break
        }
        scene?.physicsWorld.gravity = CGVector(dx: dx, dy: dy)
    }
}
