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

    class Round {
        var node: SKSpriteNode
        var scaleX: CGFloat
        var scaleY: CGFloat
        var view: SKView

        init(imageName: String, view: SKView, scaleX: CGFloat, scaleY: CGFloat) {
            self.scaleX = scaleX
            self.scaleY = scaleY
            self.view = view

            let radius: CGFloat = min(scaleX, scaleY) * 0.4
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

        var col: Int {
            get {
                return Int(floor(node.position.x / scaleX))
            }
            set {
                node.position.x = CGFloat(newValue + 1) * scaleX - 0.5 * scaleX
            }
        }

        var row: Int {
            get {
                return Int(floor(node.position.y / scaleY))
            }
            set {
                node.position.y = CGFloat(newValue + 1) * scaleY - 0.5 * scaleY
            }
        }

        var coord: Maze.Coord {
            get {
                return Maze.Coord(row: row, col: col)
            }
        }
    }

    class Marble: Round {
        override init(imageName: String, view: SKView, scaleX: CGFloat, scaleY: CGFloat) {
            super.init(imageName: imageName, view: view, scaleX: scaleX, scaleY: scaleY)
            node.physicsBody?.categoryBitMask = Collisions.marble.rawValue
            node.physicsBody?.contactTestBitMask |= Collisions.target.rawValue
        }
    }

    class Target: Round {
        override init(imageName: String, view: SKView, scaleX: CGFloat, scaleY: CGFloat) {
            super.init(imageName: imageName, view: view, scaleX: scaleX, scaleY: scaleY)
            node.physicsBody?.categoryBitMask = Collisions.target.rawValue
            node.physicsBody?.contactTestBitMask |= Collisions.marble.rawValue
            node.physicsBody?.isDynamic = false
            node.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1.0)))
        }
    }

    class Wall {
        var node: SKShapeNode
        var scaleX: CGFloat
        var scaleY: CGFloat
        var direction: Maze.Direction

        init(direction: Maze.Direction, scaleX: CGFloat, scaleY: CGFloat) {
            self.scaleX = scaleX
            self.scaleY = scaleY
            self.direction = direction

            node = SKShapeNode(rect: {
                switch direction {
                case .up, .down:
                    return CGRect(x: 0, y: 0, width: scaleX, height: 0)
                case .left, .right:
                    return CGRect(x: 0, y: 0, width: 0, height: scaleY)
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

        func moveTo(coord: Maze.Coord) {
            node.position.x = CGFloat(coord.col) * scaleX
            node.position.y = CGFloat(coord.row) * scaleY
            switch direction {
            case .up:
                node.position.y += scaleY
            case .right:
                node.position.x += scaleX
            default:
                break
            }
        }
    }

    class Solution {
        var node: SKShapeNode
        let pattern: [CGFloat] = [3.0, 2.0]

        init() {
            let bezierPath = UIBezierPath()
            node = SKShapeNode(path: bezierPath.cgPath.copy(dashingWithPhase: 2, lengths: pattern))
            node.strokeColor = .clear
            node.lineWidth = 1
        }

        func show(maze: Maze, src: Round, dst: Round, scaleX: CGFloat, scaleY: CGFloat) {
            let path = maze.solve(from: src.coord, to: dst.coord)
            let bezierPath = UIBezierPath()
            let points = path.map { coord in
                CGPoint(x: CGFloat(coord.col + 1) * scaleX - 0.5 * scaleX, y: CGFloat(coord.row + 1) * scaleY - 0.5 * scaleY)
            }
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
        var scaleY: CGFloat!
        var scaleX: CGFloat!
        var maze: Maze!
        var solution: Solution!

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
            let columns = complexity
            maze = Maze(columns: columns, rows: rows)

            scaleX = frame.width / CGFloat(columns)
            scaleY = frame.height / CGFloat(rows)

            for (y, row) in maze.maze.enumerated() {
                for (x, val) in row.enumerated() {
                    for direction in Maze.Direction.allCases {
                        if direction.rawValue & val == 0 {
                            let wall = Wall(direction: direction, scaleX: scaleX, scaleY: scaleY)
                            wall.moveTo(coord: Maze.Coord(row: y, col: x))
                            addChild(wall.node)
                        }
                    }
                }
            }

            marble = Marble(imageName: "Labyrinth_Marble", view: self.view!, scaleX: scaleX, scaleY: scaleY)
            marble.row = rows - 1
            marble.col = columns - 1
            addChild(marble.node)

            target = Target(imageName: "Labyrinth_Target", view: self.view!, scaleX: scaleX, scaleY: scaleY)
            target.row = 0
            target.col = 0
            addChild(target.node)

            physicsWorld.contactDelegate = self
            physicsWorld.gravity = CGVector(dx: 0, dy: 0)

            if motionManager.isAccelerometerAvailable {
                motionManager.startAccelerometerUpdates()
            }

            solution = Solution()
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

            solution.show(maze: maze, src: marble, dst: target, scaleX: scaleX, scaleY: scaleY)
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
