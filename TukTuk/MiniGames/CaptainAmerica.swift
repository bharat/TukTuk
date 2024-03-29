//
//  CaptainAmerica.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 8/23/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit
import CoreMotion

extension Media {
    static let CaptainAmerica = Media("CaptainAmerica")
}

final class CaptainAmerica: MiniGame {
    var title = "CaptainAmerica"
    var uivc: UIViewController = UIVC()
    static var levels: [Titled] = Array(1...10).map{ Level($0) }

    class Level: Titled {
        var level: Int
        var title: String {
            return "\(level)"
        }

        var reward: Videos {
            switch level {
            case 1:  return Videos.Reward_CaptainAmerica_vs_RedSkull
            case 2:  return Videos.Reward_Magnet_Mayhem
            case 3:  return Videos.Reward_SpiderGwen
            case 4:  return Videos.Reward_Rocket_and_Groot
            case 5:  return Videos.Reward_Chimichangas
            case 6:  return Videos.Reward_Spidey_and_IronMan
            case 7:  return Videos.Reward_Thor
            case 8:  return Videos.Reward_Hulk_BlackWidow
            case 9:  return Videos.Reward_Cello_Wars
            case 10: return Videos.Reward_Guardians_Full

            default:
                return Videos.Reward_Magnet_Mayhem
            }
        }

        var complexity: Int {
            return level + 2
        }

        init(_ level: Int) {
            self.level = level
        }
    }

    enum Collisions: UInt32 {
        case wall   = 1
        case marble = 2
        case target = 4
    }

    static let BounceSounds = [
        Sound.CaptainAmerica_Bounce_1,
        Sound.CaptainAmerica_Bounce_2,
        Sound.CaptainAmerica_Bounce_3
    ]

    enum Videos: String, CaseIterable {
        case LostShield
        case Reward_Magnet_Mayhem
        case Reward_Spidey_and_IronMan
        case Reward_Rocket_and_Groot
        case Reward_Hulk_BlackWidow
        case Reward_Chimichangas
        case Reward_CaptainAmerica_vs_RedSkull
        case Reward_Thor
        case Reward_SpiderGwen
        case Reward_Cello_Wars
        case Reward_Guardians_Full

        var video: URL {
            return Media.CaptainAmerica.video(rawValue)
        }
    }

    class UIVC: UIViewController {
        enum States {
            case Preroll
            case Scene
            case Reward
            case Done
        }
        var state: States = .Preroll

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)

            let level = Level(UserDefaults.standard.mazeLevel)
            switch state {
            case .Preroll:
                let uivc = PrerollVC()
                uivc.modalPresentationStyle = .fullScreen
                present(uivc, animated: animated)
                self.state = .Scene
            case .Scene:
                let uivc = SceneVC()
                uivc.level = level
                uivc.modalPresentationStyle = .fullScreen
                self.present(uivc, animated: animated)
                self.state = .Reward
            case .Reward:
                let uivc = RewardVC()
                uivc.level = level
                uivc.modalPresentationStyle = .fullScreen
                self.present(uivc, animated: animated)
                self.state = .Done
            case .Done:
                UserDefaults.standard.mazeLevel += 1
                self.state = .Preroll
                self.dismiss(animated: animated)
            }
        }
    }

    class PrerollVC: UIViewController {
        override func viewDidLoad() {
            super.viewDidLoad()
            DispatchQueue.main.async {
                VideoPlayer.instance.play(Videos.LostShield.video, from: self) {
                    self.dismiss(animated: true)
                }
            }
        }
    }

    class SceneVC: UIViewController {
        var scene: Scene!
        var level: Level!

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)

            Media.CaptainAmerica.play("Rescue", for: UserDefaults.standard.child)

            let skView = SKView(frame: view.frame.insetBy(dx: 8, dy: 20))
            skView.allowsTransparency = true
            view.addSubview(skView)

            scene = Scene(size: view.frame.insetBy(dx: 8, dy: 20).size)
            scene.level = level
            scene.completion = {
                Sound.CaptainAmerica_Tada.play() {
                    self.dismiss(animated: animated)
                }
            }
            skView.presentScene(scene)
        }

        override func viewWillDisappear(_ animated: Bool) {
            scene?.removeFromParent()
            scene = nil
        }
    }

    class RewardVC: UIViewController {
        var level: Level!

        override func viewDidLoad() {
            super.viewDidLoad()
            DispatchQueue.main.async {
                VideoPlayer.instance.play(self.level.reward.video, from: self) {
                    self.dismiss(animated: true)
                }
            }
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
            return CGPoint(x: CGFloat(pos.col) * scaleX, y: CGFloat(pos.row) * scaleY)
        }

        func centeredNodePosition(from pos: Maze.Position) -> CGPoint {
            return nodePosition(from: pos) + CGPoint(x: 0.5 * scaleX, y: 0.5 * scaleY)
        }
    }

    class RoundSprite {
        var node: SKSpriteNode
        var view: SKView
        var translator: Translator

        init(imageName: String, view: SKView, translator: Translator) {
            self.view = view
            self.translator = translator

            let radius: CGFloat = 0.4 * min(translator.scaleX, translator.scaleY)
            let textureNode = SKShapeNode(circleOfRadius: radius)
            textureNode.lineWidth = 1
            textureNode.fillColor = .white
            textureNode.fillTexture = SKTexture(imageNamed: imageName)
            let texture = view.texture(from: textureNode)

            node = SKSpriteNode(texture: texture)
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
                node.position = translator.centeredNodePosition(from: newValue)
            }
        }
    }

    class Marble: RoundSprite {
        init(view: SKView, translator: Translator) {
            super.init(imageName: "Labyrinth_Marble", view: view, translator: translator)
            node.physicsBody?.categoryBitMask = Collisions.marble.rawValue
            node.physicsBody?.contactTestBitMask |= Collisions.target.rawValue
        }
    }

    class Target: RoundSprite {
        init(view: SKView, translator: Translator) {
            super.init(imageName: "Labyrinth_Target", view: view, translator: translator)
            node.physicsBody?.categoryBitMask = Collisions.target.rawValue
            node.physicsBody?.contactTestBitMask |= Collisions.marble.rawValue
            node.physicsBody?.isDynamic = false
            node.run(SKAction.repeatForever(
                SKAction.group([
                    SKAction.rotate(byAngle: 2 * .pi, duration: 2.0),
                    SKAction.sequence([
                        SKAction.scale(by: 0.5, duration: 1.0),
                        SKAction.scale(by: 2.0, duration: 1.0)
                        ])
                    ])
                ))
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
            node = SKShapeNode(path: bezierPath.cgPath)
            node.strokeColor = .clear
            node.lineWidth = 2
        }

        func show(maze: Maze, src: RoundSprite, dst: RoundSprite) {
            if let path = maze.solve(from: src.mazePosition, to: dst.mazePosition), path.count > 4 {
                let points = [src.node.position] + path[0...path.count/3].map {
                    pos in translator.centeredNodePosition(from: pos)
                }

                let bezierPath = Bezier.curveFrom(points: points)
                node.path = bezierPath.cgPath.copy(dashingWithPhase: 2, lengths: pattern)
                node.strokeColor = .green
                node.isHidden = false
            }
        }

        func hide() {
            node.isHidden = true
        }
    }

    class Scene: SKScene, SKPhysicsContactDelegate {
        let motionManager = CMMotionManager()
        var completion: () -> () = { }
        var level: Level!
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

            let rows = Int(CGFloat(level.complexity) * (frame.height / frame.width))
            let cols = level.complexity
            translator = Translator(frame: frame, rows: rows, cols: cols)
            maze = Maze(cols: cols, rows: rows)

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

            marble = Marble(view: self.view!, translator: translator)
            marble.mazePosition = Maze.Position(row: rows - 1, col: cols - 1) // top right
            addChild(marble.node)

            target = Target(view: self.view!, translator: translator)
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
            motionManager.stopAccelerometerUpdates()
            completion()
        }

        var lastMoveTime: TimeInterval = 0.0
        var lastMarblePosition = Maze.Position(row: -1, col: -1)
        override func update(_ currentTime: TimeInterval) {
            super.update(currentTime)

            if let data = motionManager.accelerometerData {
                physicsWorld.gravity = CGVector(dx: data.acceleration.x * 5.0, dy: data.acceleration.y * 5.0)
            }

            if marble.mazePosition != lastMarblePosition {
                lastMoveTime = currentTime
                lastMarblePosition = marble.mazePosition
                solution.hide()
            }

            if currentTime - lastMoveTime > 3.0 {
                solution.show(maze: maze, src: marble, dst: target)
            }
        }

        func didBegin(_ contact: SKPhysicsContact) {
            switch contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask {
            case Collisions.marble.rawValue | Collisions.target.rawValue:
                scene?.isPaused = true
                done()
            case Collisions.marble.rawValue | Collisions.wall.rawValue:
                if SoundPlayer.instance.player?.isPlaying == false {
                    BounceSounds.randomElement()!.play()
                }
            default:
                break
            }
        }
    }
}

// Enable arrow keys to simulate motion in the simulator
extension CaptainAmerica.SceneVC {
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
