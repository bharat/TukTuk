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

    //  Adapted from: https://rosettacode.org/wiki/Maze_generation#Swift
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
            case .up:    return ( 0,  1)
            case .down:  return ( 0, -1)
            case .right: return ( 1,  0)
            case .left:  return (-1,  0)
            }
        }
    }

    class Maze {
        let columns: Int
        let rows: Int
        var maze: [[Int]]

        struct Coord: Equatable, Hashable {
            var x: Int
            var y: Int
        }

        init(columns: Int, rows: Int) {
            self.columns = columns
            self.rows = rows
            self.maze = Array(repeating: Array(repeating: 0, count: columns), count: rows)
            generate(Coord(x: 0, y: 0))
        }

        private func generate(_ coord: Coord) {
            for direction in Direction.allCases.shuffled() {
                let (dx, dy) = direction.diff
                let new = Coord(x: coord.x + dx, y: coord.y + dy)
                if inBounds(new) && maze[new.y][new.x] == 0 {
                    maze[coord.y][coord.x] |= direction.rawValue
                    maze[new.y][new.x] |= direction.opposite.rawValue
                    generate(new)
                }
            }
        }

        func solve(from src: Coord, to dst: Coord, path: [Coord] = []) -> [Coord]? {
            if src == dst {
                return path
            }

            for dir in Direction.allCases {
                let (dx, dy) = dir.diff
                let coord = Coord(x: src.x + dx, y: src.y + dy)
                if legalMove(from: src, direction: dir) && inBounds(coord) && !path.contains(coord) {
                    if let solution = solve(from: coord, to: dst, path: path + [coord]) {
                        return solution
                    }
                }
            }

            return nil
        }

        private func legalMove(from src: Coord, direction: Direction) -> Bool {
            return maze[src.y][src.x] & direction.rawValue > 0
        }

        private func inBounds(_ coord: Coord) -> Bool {
            return inBounds(value: coord.x, upper: columns) && inBounds(value: coord.y, upper: rows)
        }

        private func inBounds(value: Int, upper: Int) -> Bool {
            return (value >= 0) && (value < upper)
        }
    }

    enum Collisions: UInt32 {
        case wall   = 1
        case marble = 2
        case target = 4
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

            let radius: CGFloat = min(scaleX, scaleY) * 0.3
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
                return Maze.Coord(x: col, y: row)
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
        var direction: Direction

        init(direction: Direction, scaleX: CGFloat, scaleY: CGFloat) {
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

        func moveTo(row: Int, col: Int) {
            node.position.x = CGFloat(col) * scaleX
            node.position.y = CGFloat(row) * scaleY
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

    class Scene: SKScene, SKPhysicsContactDelegate {
        let motionManager = CMMotionManager()
        var completion: () -> () = { }
        var complexity: Int = 2
        var marble: Marble!
        var target: Target!
        var scaleY: CGFloat!
        var scaleX: CGFloat!
        var maze: Maze!

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
                    for direction in Direction.allCases {
                        if direction.rawValue & val == 0 {
                            let wall = Wall(direction: direction, scaleX: scaleX, scaleY: scaleY)
                            wall.moveTo(row: y, col: x)
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
        }

        func done() {
            motionManager.startAccelerometerUpdates()
            completion()
        }

        var lastTimeWePresentedASolution: TimeInterval?

        override func update(_ currentTime: TimeInterval) {
            super.update(currentTime)

            if let data = motionManager.accelerometerData {
                physicsWorld.gravity = CGVector(dx: data.acceleration.x * 5.0, dy: data.acceleration.y * 5.0)
            }

            print(maze.solve(from: marble.coord, to: target.coord))
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
