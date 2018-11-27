//
//  AllyMaze.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 8/23/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

final class AllyMaze: MiniGame {
    static var title = "Ally Labyrinth"
    var uivc: UIViewController = UIVC()

    class UIVC: UIViewController {
        override func viewDidLoad() {
            let effect = UIBlurEffect(style: .light)
            let effectView = UIVisualEffectView(effect: effect)
            effectView.frame = view.frame
            view.addSubview(effectView)

            let scene = AllyMaze.Scene()
            scene.completion = {
//                VideoPlayer.play(hero.video, from: self) {
//                    self.dismiss(animated: true)
//                }
            }

            let sceneView = SCNView(frame: view.frame)
            sceneView.scene = scene
//            sceneView.backgroundColor = .red
            sceneView.autoenablesDefaultLighting = false
            sceneView.allowsCameraControl = false
            sceneView.gestureRecognizers = [
                UITapGestureRecognizer(target: sceneView.scene, action: #selector(scene.tap(gesture:)))
            ]
            effectView.contentView.addSubview(sceneView)

            scene.start() {
            }
        }
    }

    enum Collisions: UInt32 {
        case floor  = 1
        case ball   = 2
    }

    //  Adapted from: https://rosettacode.org/wiki/Maze_generation#Swift
    class Maze {
        enum Direction: Int {
            case north = 1
            case south = 2
            case east = 4
            case west = 8

            static var allDirections: [Direction] {
                return [.north, .south, .east, .west]
            }

            var opposite:Direction {
                switch self {
                case .north:
                    return .south
                case .south:
                    return .north
                case .east:
                    return .west
                case .west:
                    return .east
                }
            }

            var diff: (Int, Int) {
                switch self {
                case .north:
                    return (0, -1)
                case .south:
                    return (0, 1)
                case .east:
                    return (1, 0)
                case .west:
                    return (-1, 0)
                }
            }
        }

        let width: Int
        let height: Int
        var maze: [[Int]]

        init(width: Int, height: Int) {
            self.width = height
            self.height = height
            let column = [Int](repeating: 0, count: height)
            self.maze = [[Int]](repeating: column, count: width)
            generate(0, 0)
        }

        private func generate(_ cx:Int, _ cy:Int) {
            var directions = Direction.allDirections
            directions.shuffle()
            for direction in directions {
                let (dx, dy) = direction.diff
                let nx = cx + dx
                let ny = cy + dy
                if inBounds(nx, ny) && maze[nx][ny] == 0 {
                    maze[cx][cy] |= direction.rawValue
                    maze[nx][ny] |= direction.opposite.rawValue
                    generate(nx, ny)
                }
            }
        }

        private func inBounds(_ testX: Int, _ testY: Int) -> Bool {
            return inBounds(value: testX, upper: width) && inBounds(value: testY, upper: height)
        }

        private func inBounds(value: Int, upper: Int) -> Bool {
            return (value >= 0) && (value < upper)
        }
    }

    class Scene: SCNScene {
        var completion: () -> () = { }

        required init(coder: NSCoder) {
            fatalError("Not yet implemented")
        }

        override init() {
            super.init()

            let camera = SCNNode()
            camera.camera = SCNCamera()
            camera.camera?.automaticallyAdjustsZRange = true
            camera.position = SCNVector3(x: 0, y: 300, z: 50)
            camera.look(at: SCNVector3(x: 0, y: 0, z: 0))
            rootNode.addChildNode(camera)

            let omniLight = SCNNode()
            omniLight.light = SCNLight()
            omniLight.light!.type = .omni
            omniLight.light!.color = UIColor(white: 1.0, alpha: 1.0)
            omniLight.position = SCNVector3Make(0, 0, 100)
            rootNode.addChildNode(omniLight)

            let groundMaterial = SCNMaterial()
            groundMaterial.diffuse.contents = UIColor(white: 0.25, alpha: 0.5)
            let groundGeometry = SCNFloor()
            groundGeometry.reflectivity = 0.25
            groundGeometry.materials = [groundMaterial]
            let groundShape = SCNPhysicsShape(geometry: groundGeometry, options: nil)
            let groundBody = SCNPhysicsBody(type: .kinematic, shape: groundShape)
            let ground = SCNNode(geometry: groundGeometry)
            ground.physicsBody = groundBody
            rootNode.addChildNode(ground)

            let gravityField = SCNPhysicsField.linearGravity()
            gravityField.strength = 2

            let sphere = SCNSphere(radius: 5.0)
            let material = SCNMaterial()
            material.diffuse.contents = UIImage(named: "FaceSquares_2")
            sphere.materials = [material]
            let ball = SCNNode(geometry: sphere)
            ball.position = SCNVector3(x: 0, y: 80, z: 0)
            ball.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: sphere, options: nil))
            ball.physicsBody?.restitution = 0.95
            rootNode.addChildNode(ball)

            physicsWorld.speed = 10.0
            physicsWorld.gravity = SCNVector3(x: 0, y: -9.8, z: 0)

            let horizonalWallBox = SCNBox(width: 10, height: 5, length: 2, chamferRadius: 1)
            horizonalWallBox.materials = [SCNMaterial()]
            horizonalWallBox.materials[0].diffuse.contents = UIColor.cyan

            let verticalWallBox = SCNBox(width: 2, height: 5, length: 10, chamferRadius: 1)
            verticalWallBox.materials = [SCNMaterial()]
            verticalWallBox.materials[0].diffuse.contents = UIColor.magenta

            let startX = -50
            let startZ = -50
            let maze = Maze(width: 10, height: 10)

            for (x, row) in maze.maze.enumerated() {
                for (y, val) in row.enumerated() {
                    if val & Maze.Direction.north.rawValue == 0 {
                        // there's a wall to the north
                        let wall = SCNNode(geometry: horizonalWallBox)
                        wall.pivot = SCNMatrix4MakeTranslation(Float(-horizonalWallBox.length), Float(horizonalWallBox.height), Float(-horizonalWallBox.width))
                        wall.position = SCNVector3(x: Float(startX + 10 * x), y: 0, z: Float(startZ + 10 * y))
                        rootNode.addChildNode(wall)
                    }
                    if val & Maze.Direction.south.rawValue == 0 {
                        // there's a wall to the south
                        let wall = SCNNode(geometry: verticalWallBox)
                        wall.pivot = SCNMatrix4MakeTranslation(Float(-verticalWallBox.length), Float(verticalWallBox.height), Float(-verticalWallBox.width))
                        wall.position = SCNVector3(x: Float(startX + 10 * x), y: 0, z: Float(startZ + 10 * (y + 1)))
                        rootNode.addChildNode(wall)
                    }
                    if val & Maze.Direction.west.rawValue == 0 {
                        // there's a wall to the west
                        let wall = SCNNode(geometry: horizonalWallBox)
                        wall.pivot = SCNMatrix4MakeTranslation(Float(-horizonalWallBox.length), Float(horizonalWallBox.height), Float(-horizonalWallBox.width))
                        wall.position = SCNVector3(x: Float(startX + 10 * x), y: 0, z: Float(startZ + 10 * y))
                        rootNode.addChildNode(wall)
                    }
                    if val & Maze.Direction.east.rawValue == 0 {
                        // there's a wall to the east
                        let wall = SCNNode(geometry: verticalWallBox)
                        wall.pivot = SCNMatrix4MakeTranslation(Float(-verticalWallBox.length), Float(verticalWallBox.height), Float(-verticalWallBox.width))
                        wall.position = SCNVector3(x: Float(startX + 10 * (x + 1)), y: 0, z: Float(startZ + 10 * y))
                        rootNode.addChildNode(wall)
                    }
                }
            }

        }

        @objc func tap(gesture: UITapGestureRecognizer) {
//            gesture.location(in: <#T##UIView?#>)
            print("Tap!")
            print(gesture)
        }

        func start(completion: @escaping () -> ()) {
        }
    }
}
