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
        override func viewDidAppear(_ animated: Bool) {
            let effect = UIBlurEffect(style: .light)
            let effectView = UIVisualEffectView(effect: effect)
            effectView.frame = view.frame
            view.addSubview(effectView)

            let skView = SKView(frame: view.frame.insetBy(dx: 8, dy: 20))
            skView.allowsTransparency = true
            effectView.contentView.addSubview(skView)

            let scene = Scene(size: view.frame.size)
            scene.complexity = 2
            scene.completion = {
                self.dismiss(animated: true)
            }
            skView.presentScene(scene)
        }
    }

    //  Adapted from: https://rosettacode.org/wiki/Maze_generation#Swift
    class Maze {
        enum Direction: Int {
            case up      =  1
            case down    =  2
            case left    =  4
            case right   =  8

            static var allDirections: [Direction] {
                return [.up, .down, .left, .right]
            }

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
            dump()
        }

        private func generate(_ cx:Int, _ cy:Int) {
            for direction in Direction.allDirections.shuffled() {
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

        func dump() {
            for r in self.maze {
                print(r.map { String(format: "%3d", $0) }.joined())
            }
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
            let marbleNode = SKShapeNode(circleOfRadius: radius)
            marbleNode.lineWidth = 1
            marbleNode.fillColor = .white
            marbleNode.fillTexture = SKTexture(imageNamed: "Labyrinth_Marble")
            let marbleTexture = self.view?.texture(from: marbleNode)

            let marble: SKSpriteNode = SKSpriteNode(texture: marbleTexture)
            marble.physicsBody = SKPhysicsBody(circleOfRadius: radius)
            marble.physicsBody?.usesPreciseCollisionDetection = true
            marble.physicsBody?.restitution = 0.2
            marble.physicsBody?.categoryBitMask = Collisions.marble.rawValue
            marble.physicsBody?.contactTestBitMask = Collisions.wall.rawValue
            marble.position = CGPoint(x: CGFloat(columns) * xScale - 0.5 * xScale, y: CGFloat(rows) * yScale - 0.5 * yScale)
            marble.zRotation = 45.0 * [-1, 1].randomElement()!
            self.addChild(marble)

            let targetNode = SKShapeNode(circleOfRadius: radius)
            targetNode.lineWidth = 1
            targetNode.fillColor = .white
            targetNode.fillTexture = SKTexture(imageNamed: "Labyrinth_Target")
            let targetTexture = self.view?.texture(from: targetNode)

            let target: SKSpriteNode = SKSpriteNode(texture: targetTexture)
            target.physicsBody = SKPhysicsBody(circleOfRadius: radius)
            target.physicsBody?.usesPreciseCollisionDetection = true
            target.physicsBody?.restitution = 0.2
            target.physicsBody?.categoryBitMask = Collisions.target.rawValue
            target.physicsBody?.contactTestBitMask = Collisions.wall.rawValue
            target.physicsBody?.isDynamic = false
            target.position = CGPoint(x: 0.5 * xScale, y: 0.5 * yScale)
            self.addChild(target)
            target.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1.0)))

            physicsWorld.contactDelegate = self
            physicsWorld.gravity = CGVector(dx: 0, dy: 0)

            motionManager.startAccelerometerUpdates()
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
//            if contact.bodyA.node == target || contact.bodyB.node == target {
//                hammer.thud()
//            }
        }
    }
}
