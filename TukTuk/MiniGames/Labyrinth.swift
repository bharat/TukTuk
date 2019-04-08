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

    func preloadableAssets() -> [URL] {
        return []
    }

    class UIVC: UIViewController {
        var scene: Scene!

        override func viewDidAppear(_ animated: Bool) {
            let effect = UIBlurEffect(style: .light)
            let effectView = UIVisualEffectView(effect: effect)
            effectView.frame = view.frame
            view.addSubview(effectView)

            let skView = SKView(frame: view.frame.insetBy(dx: 8, dy: 20))
            skView.allowsTransparency = true
            effectView.contentView.addSubview(skView)

            scene = Scene(size: view.frame.size)
            scene.complexity = 20
            scene.completion = {
                self.dismiss(animated: true)
            }
            skView.presentScene(scene)
        }
    }

    //  Adapted from: https://rosettacode.org/wiki/Maze_generation#Swift
    class Maze {
        enum Direction: Int, CaseIterable {
            case up      =  1
            case down    =  2
            case left    =  4
            case right   =  8

            var opposite: Direction {
                switch self {
                case .up:    return .down
                case .down:  return .up
                case .left:  return .right
                case .right: return .left
                }
            }

            var diff: (Int, Int) {
                switch self {
                case .up:    return ( 0, -1)
                case .down:  return ( 0,  1)
                case .right: return ( 1,  0)
                case .left:  return (-1,  0)
                }
            }
        }

        let columns: Int
        let rows: Int
        var maze: [[Int]]

        init(columns: Int, rows: Int) {
            self.columns = columns
            self.rows = rows
            self.maze = Array(repeating: Array(repeating: 0, count: columns), count: rows)
            generate(0, 0)
        }

        private func generate(_ cx:Int, _ cy:Int) {
            for direction in Direction.allCases.shuffled() {
                let (dx, dy) = direction.diff
                let nx = cx + dx
                let ny = cy + dy
                if inBounds(nx, ny) && maze[ny][nx] == 0 {
                    maze[cy][cx] |= direction.rawValue
                    maze[ny][nx] |= direction.opposite.rawValue
                    generate(nx, ny)
                }
            }
        }

        private func inBounds(_ testX: Int, _ testY: Int) -> Bool {
            return inBounds(value: testX, upper: columns) && inBounds(value: testY, upper: rows)
        }

        private func inBounds(value: Int, upper: Int) -> Bool {
            return (value >= 0) && (value < upper)
        }
    }

    enum Collisions: UInt32 {
        case wall   = 1
        case marble = 2
        case target = 3
    }

    class Scene: SKScene, SKPhysicsContactDelegate {
        let motionManager = CMMotionManager()
        var completion: () -> () = { }
        var complexity: Int = 2
        var marbleNode: SKSpriteNode!
        var targetNode: SKSpriteNode!

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

            let border = SKShapeNode(rect: view.frame)
            border.lineWidth = 4
            border.strokeColor = .white
            border.physicsBody = SKPhysicsBody(edgeLoopFrom: view.frame)
            border.physicsBody?.categoryBitMask = Collisions.wall.rawValue
            border.physicsBody?.restitution = 0.2
            border.physicsBody?.isDynamic = false
            addChild(border)

            let columns = complexity
            let rows = Int(CGFloat(complexity) * (height / width))
            let maze = Maze(columns: columns, rows: rows)
            let xScale = width / CGFloat(columns)
            let yScale = height / CGFloat(rows)
            var walls: [CGRect] = []

            for (y, row) in maze.maze.enumerated() {
                for (x, val) in row.enumerated() {
                    if Maze.Direction.up.rawValue & val == 0 {
                        walls.append(CGRect(x: x, y: y, width: 1, height: 0))
                    }
                    if Maze.Direction.down.rawValue & val == 0 {
                        walls.append(CGRect(x: x, y: y + 1, width: 1, height: 0))
                    }
                    if Maze.Direction.left.rawValue & val == 0 {
                        walls.append(CGRect(x: x, y: y, width: 0, height: 1))
                    }
                    if Maze.Direction.right.rawValue & val == 0 {
                        walls.append(CGRect(x: x + 1, y: y, width: 0, height: 1))
                    }
                }
            }

            walls.forEach {
                // Account for the frame's inset from (0, 0) and scale it up
                let rect = CGRect(x: view.frame.minX + $0.minX * xScale, y: view.frame.minY + $0.minY * yScale, width: $0.width * xScale, height: $0.height * yScale)
                let wall = SKShapeNode(rect: rect)
                wall.lineWidth = 4
                wall.strokeColor = .white
                wall.physicsBody = SKPhysicsBody(edgeChainFrom: wall.path!)
                wall.physicsBody?.categoryBitMask = Collisions.wall.rawValue
                wall.physicsBody?.restitution = 0.2
                wall.physicsBody?.isDynamic = false
                addChild(wall)
            }

            let radius: CGFloat = min(xScale, yScale) * 0.3
            let marbleTextureNode = SKShapeNode(circleOfRadius: radius)
            marbleTextureNode.lineWidth = 1
            marbleTextureNode.fillColor = .white
            marbleTextureNode.fillTexture = SKTexture(imageNamed: "Labyrinth_Marble")
            let marbleTexture = self.view?.texture(from: marbleTextureNode)

            marbleNode = SKSpriteNode(texture: marbleTexture)
            marbleNode.physicsBody = SKPhysicsBody(circleOfRadius: radius)
            marbleNode.physicsBody?.usesPreciseCollisionDetection = true
            marbleNode.physicsBody?.restitution = 0.2
            marbleNode.physicsBody?.categoryBitMask = Collisions.marble.rawValue
            marbleNode.physicsBody?.contactTestBitMask = Collisions.wall.rawValue
            marbleNode.position = CGPoint(x: CGFloat(columns) * xScale - 0.5 * xScale, y: CGFloat(rows) * yScale - 0.5 * yScale)
            marbleNode.zRotation = 45.0 * [-1, 1].randomElement()!
            self.addChild(marbleNode)

            let targetTextureNode = SKShapeNode(circleOfRadius: radius)
            targetTextureNode.lineWidth = 1
            targetTextureNode.fillColor = .white
            targetTextureNode.fillTexture = SKTexture(imageNamed: "Labyrinth_Target")
            let targetTexture = self.view?.texture(from: targetTextureNode)

            targetNode = SKSpriteNode(texture: targetTexture)
            targetNode.physicsBody = SKPhysicsBody(circleOfRadius: radius)
            targetNode.physicsBody?.usesPreciseCollisionDetection = true
            targetNode.physicsBody?.restitution = 0.2
            targetNode.physicsBody?.categoryBitMask = Collisions.target.rawValue
            targetNode.physicsBody?.contactTestBitMask = Collisions.wall.rawValue
            targetNode.physicsBody?.isDynamic = false
            targetNode.position = CGPoint(x: 0.5 * xScale, y: 0.5 * yScale)
            self.addChild(targetNode)
            targetNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1.0)))

            physicsWorld.contactDelegate = self
            physicsWorld.gravity = CGVector(dx: 0, dy: 0)

            if motionManager.isAccelerometerAvailable {
                motionManager.startAccelerometerUpdates()
            }
        }

        deinit {
            print("Deinit Labyrinth scene")
            motionManager.startAccelerometerUpdates()
        }

        override func update(_ currentTime: TimeInterval) {
            if let data = motionManager.accelerometerData {
                physicsWorld.gravity = CGVector(dx: data.acceleration.x * 5.0, dy: data.acceleration.y * 5.0)
            }
        }

        func didBegin(_ contact: SKPhysicsContact) {
            if contact.bodyA.node == targetNode || contact.bodyB == targetNode {
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
        print("Gravity: \(dx), \(dy)")
        scene.physicsWorld.gravity = CGVector(dx: dx, dy: dy)
    }
}
