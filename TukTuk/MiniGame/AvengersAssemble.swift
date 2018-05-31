//
//  HeroBlocks.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/14/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

final class AvengersAssemble: MiniGame {
    static var title = "Avengers Assemble!"
    var uivc: UIViewController = UIVC()

    enum Pace: TimeInterval {
        case immediate  = 0.0
        case veryFast   = 0.05
        case fast       = 0.125
        case normal     = 0.25
        case slow       = 0.50
        case verySlow   = 5.0

        var duration: TimeInterval {
            return rawValue
        }
    }

    enum Hero: String {
        case CaptainAmerica
        case Hawkeye
        case IronMan
        case Hulk
        case Thor
        case BlackWidow

        static var all: [Hero]  = [.CaptainAmerica, .Hawkeye, .IronMan, .Hulk, .Thor, .BlackWidow]

        var rotation: (x: CGFloat, y: CGFloat) {
            switch self {
            case .CaptainAmerica:   return (     0.0,  0.0     )
            case .Hawkeye:          return (     0.0,  -.pi / 2)
            case .IronMan:          return (     0.0,   .pi    )
            case .Hulk:             return (     0.0,   .pi / 2)
            case .Thor:             return ( .pi / 2,  0.0     )
            case .BlackWidow:       return (-.pi / 2,  0.0     )
            }
        }

        var neighbor: (left: Hero, right: Hero, up: Hero, down: Hero) {
            switch self {
            case .CaptainAmerica:   return (.Hulk, .Hawkeye, .Thor, .BlackWidow)
            case .Hawkeye:          return (.CaptainAmerica, .IronMan, .Thor, .BlackWidow)
            case .IronMan:          return (.Hawkeye, .Hulk, .Thor, .BlackWidow)
            case .Hulk:             return (.IronMan, .CaptainAmerica, .Thor, .BlackWidow)
            case .Thor:             return (.Hulk, .Hawkeye, .IronMan, .CaptainAmerica)
            case .BlackWidow:       return (.Hulk, .Hawkeye, .CaptainAmerica, .IronMan)
            }
        }

        var image: UIImage? {
            return UIImage(named: "Avenger_\(rawValue)")
        }

        var sound: URL {
            return Catalog.sound("AvengersAssemble/\(rawValue).mp3")
        }

        var video: URL {
            return Catalog.video("AvengersAssemble/\(rawValue).mp4")
        }
    }

    static var Assemble             = Catalog.sound("AvengersAssemble/Assemble.mp3")
    static var ChooseAnAvenger      = Catalog.sound("AvengersAssemble/ChooseAnAvenger.mp3")
    static var Tada                 = Catalog.sound("AvengersAssemble/Tada.mp3")

    class UIVC: UIViewController {
        override func viewDidLoad() {
            AudioPlayer.play(Assemble)

            let effect = UIBlurEffect(style: .light)
            let effectView = UIVisualEffectView(effect: effect)
            effectView.frame = view.frame
            view.addSubview(effectView)

            let scene = AvengersAssemble.Scene()
            scene.completion = { hero in
                VideoPlayer.play(hero.video, from: self) {
                    self.dismiss(animated: true)
                }
            }

            let sceneView = SCNView(frame: view.frame)
            sceneView.scene = scene
            sceneView.backgroundColor = .black
            sceneView.autoenablesDefaultLighting = false
            sceneView.allowsCameraControl = false
            sceneView.gestureRecognizers =
                [UISwipeGestureRecognizerDirection.left, .right, .up, .down].map {
                    let gesture = UISwipeGestureRecognizer(target: sceneView.scene, action: #selector(scene.swipeBlock(gesture:)))
                    gesture.direction = $0
                    gesture.isEnabled = false
                    return gesture
                }
            effectView.contentView.addSubview(sceneView)

            scene.start() {
                sceneView.gestureRecognizers?.forEach { $0.isEnabled = true }
            }
        }
    }

    class Scene: SCNScene {
        var blocks: [Block] = []
        var completion: (Hero) -> () = { _ in }

        override init() {
            super.init()

            let camera = SCNNode()
            camera.camera = SCNCamera()
            camera.camera?.zFar = 400.0
            camera.position = SCNVector3(x: 0, y: 0, z: 100)
            rootNode.addChildNode(camera)
            
            let omniLight = SCNNode()
            omniLight.light = SCNLight()
            omniLight.light!.type = .omni
            omniLight.light!.color = UIColor(white: 1.0, alpha: 1.0)
            omniLight.position = SCNVector3Make(0, 0, 100)
            rootNode.addChildNode(omniLight)

            let box = SCNBox(width: 10.0, height: 10.0, length: 10.0, chamferRadius: 1)
            box.materials = Hero.all.map {
                let material = SCNMaterial()
                material.diffuse.contents = $0.image
                return material
            }

            for _ in 0...3 {
                let block = Block(geometry: box)
                block.position = SCNVector3(x: 0, y: 0, z: 120.0)
                block.show(Hero.all.random, pace: .immediate)

                rootNode.addChildNode(block)
                blocks.append(block)
            }
        }

        func start(completion: @escaping () -> ()) {
            let yDest: [Float] = [30.0, 10.0, -10.0, -30.0]
            for (i, block) in blocks.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 * Double(i)) {
                    block.heroicArrival(of: Hero.all.random, at: SCNVector3(x: 0, y: yDest[i], z: 20)) {
                        block.entice()
                    }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 9.0) {
                AudioPlayer.play(ChooseAnAvenger)
                completion()
            }
        }
        
        required init(coder: NSCoder) {
            fatalError("Not yet implemented")
        }

        @objc func swipeBlock(gesture: UISwipeGestureRecognizer) {
            let sceneView = gesture.view as! SCNView
            let point = gesture.location(in: sceneView)
            let hits = sceneView.hitTest(point, options: nil)
            
            if let block = hits.first?.node as? Block {
                // stop all wiggling
                blocks.forEach { $0.stopEnticing() }

                if gesture.state == .ended {
                    var new: Hero
                    switch gesture.direction {
                    case .right:    new = block.hero.neighbor.left
                    case .left:     new = block.hero.neighbor.right
                    case .up:       new = block.hero.neighbor.down
                    case .down:     new = block.hero.neighbor.up
                    default:        new = .CaptainAmerica
                    }

                    AudioPlayer.play(new.sound)
                    block.show(new) {
                        // If they're all the same, we're ready for the next phase
                        if (self.blocks.map { $0.hero }).allTheSame() {
                            DispatchQueue.main.asyncAfter(deadline: .now() + Pace.normal.duration) {
                                gesture.isEnabled = false
                                self.select(hero: self.blocks[0].hero, from: block)
                            }
                        }
                    }
                }
            }
        }
        
        func select(hero: Hero, from block: Block) {
            AudioPlayer.play(Tada)

            blocks.filter { $0 != block }.forEach {
                $0.runAction(SCNAction.fadeOut(duration: 1.0))
            }
            
            block.runAction(SCNAction.sequence([
                SCNAction.wait(duration: 1.0),
                SCNAction.group([
                    SCNAction.move(to: SCNVector3(0, 0, 90), duration: 2.0),
                    SCNAction.rotateBy(x: 0, y: 0, z: 2 * .pi, duration: 2.0),
                    ]),
                ])) {
                    DispatchQueue.main.async {
                        self.completion(hero)
                    }
            }
        }
    }

    class Block: SCNNode {
        var hero: Hero = .CaptainAmerica
        
        init(geometry: SCNGeometry?) {
            super.init()
            self.geometry = geometry
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func show(_ new: Hero, pace: Pace = .normal, completion: @escaping () -> () = {}) {
            guard action(forKey: "show") == nil else { return }

            // Rotate through the initial face so that we get the right vertical orientation
            let x = Hero.CaptainAmerica.rotation.y - hero.rotation.x + new.rotation.x
            let y = Hero.CaptainAmerica.rotation.y - hero.rotation.y + new.rotation.y

            runAction(
                SCNAction.rotateBy(x: x, y: y, z: 0, duration: pace.duration),
                forKey: "show") {
                    self.hero = new
                    completion()
            }
        }

        func heroicArrival(of new: Hero, at dest: SCNVector3, completion: @escaping () -> ()) {
            hero = new
            runAction(
                SCNAction.group([
                    SCNAction.move(to: dest, duration: Pace.verySlow.duration),
                    SCNAction.rotateTo(x: hero.rotation.x, y: hero.rotation.y, z: 0, duration: Pace.verySlow.duration),
                    ]),
                completionHandler: completion
            )
        }

        func entice() {
            runAction(
                SCNAction.repeatForever(
                    SCNAction.sequence([
                        SCNAction.repeat(
                            SCNAction.sequence([
                                SCNAction.rotateBy(x: 0, y: -0.32, z: 0, duration: 0.025),
                                SCNAction.rotateBy(x: 0, y:  0.64, z: 0, duration: 0.050),
                                SCNAction.rotateBy(x: 0, y: -0.32, z: 0, duration: 0.025),
                                ]),
                            count: 3),
                        SCNAction.wait(duration: [5.0, 8.0, 10.0].random),
                        ])
                    ),
                forKey: "entice"
            )
        }

        func stopEnticing() {
            removeAction(forKey: "entice")
        }
    }
}
