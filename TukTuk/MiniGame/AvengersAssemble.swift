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
    static var title = "Avengers blocks!"
    var uivc: UIViewController = UIVC()

    class UIVC: UIViewController {
        var sceneView: SCNView!

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
            
            let gesture = UITapGestureRecognizer(target: scene, action: #selector(scene.tapHeroBlock(gesture:)))
            gesture.isEnabled = false
            
            sceneView = SCNView(frame: view.frame)
            sceneView.backgroundColor = .black
            sceneView.autoenablesDefaultLighting = false
            sceneView.allowsCameraControl = false
            sceneView.scene = scene
            sceneView.gestureRecognizers = [ gesture ]
            effectView.contentView.addSubview(sceneView)

            scene.start() {
                gesture.isEnabled = true
            }
        }
    }

    enum Hero: String {
        case CaptainAmerica = "CaptainAmerica"
        case HawkEye        = "HawkEye"
        case IronMan        = "IronMan"
        case Hulk           = "Hulk"
        case Thor           = "Thor"
        case BlackWidow     = "BlackWidow"
        
        static var all: [Hero]  = [.CaptainAmerica, .HawkEye, .IronMan, .Hulk, .Thor, .BlackWidow]
        
        var rotation: (x: CGFloat, y: CGFloat) {
            switch self {
            case .CaptainAmerica:   return (x: 0.0,       y: 0.0     )
            case .HawkEye:          return (x: 0.0,       y: .pi / -2)
            case .IronMan:          return (x: 0.0,       y: .pi     )
            case .Hulk:             return (x: 0.0,       y: .pi / 2 )
            case .Thor:             return (x: .pi / 2,   y: 0.0     )
            case .BlackWidow:       return (x: .pi / -2,  y: 0.0     )
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

    static var RotateClick          = Catalog.sound("AvengersAssemble/RotateClick.mp3")
    static var Assemble             = Catalog.sound("AvengersAssemble/Assemble.mp3")
    static var ChooseAnAvenger      = Catalog.sound("AvengersAssemble/ChooseAnAvenger.mp3")
    static var Tada                 = Catalog.sound("AvengersAssemble/Tada.mp3")

    enum Pace: TimeInterval {
        case immediate  = 0.0
        case fast       = 0.125
        case normal     = 0.25
        case slow       = 0.50
        case verySlow   = 5.0
    }
    
    class Scene: SCNScene {
        var blocks: [Block] = []
        var completion: (Hero) -> () = {_ in }

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
        
        @objc func tapHeroBlock(gesture: UITapGestureRecognizer) {
            let sceneView = gesture.view as! SCNView
            let point = gesture.location(in: sceneView)
            let hits = sceneView.hitTest(point, options: nil)
            
            if let block = hits.first?.node as? Block {
                // stop all wiggling
                blocks.forEach { $0.stopEnticing() }
                
                AudioPlayer.play(RotateClick)
                while true {
                    let rnd = Hero.all.random
                    if rnd != block.hero {
                        block.show(rnd) {
                            AudioPlayer.play(block.hero.sound)
                        }
                        break
                    }
                }


                // If they're all the same, we're ready for the next phase
                if (blocks.map { $0.hero }).allTheSame() {
                    gesture.isEnabled = false
                    self.selectHero(self.blocks[0].hero)
                }
            }
        }
        
        func selectHero(_ hero: Hero) {
            AudioPlayer.play(Tada)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                for (i, block) in self.blocks.enumerated() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 * Double(i)) {
                        block.runAction(SCNAction.move(by: SCNVector3(0, 0, -500), duration: 1.0))
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
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
            removeAction(forKey: "show")

            if hero != new {
                hero = new
                let rot = hero.rotation
                runAction(SCNAction.rotateTo(x: rot.x, y: rot.y, z: 0, duration: pace.rawValue),
                          forKey: "show",
                          completionHandler: completion)
            }
        }

        func heroicArrival(of hero: Hero, at dest: SCNVector3, completion: @escaping () -> ()) {
            self.hero = hero
            let rot = hero.rotation

            runAction(
                SCNAction.group([
                    SCNAction.move(to: dest, duration: Pace.verySlow.rawValue),
                    SCNAction.rotateTo(x: rot.x, y: rot.y, z: 0, duration: Pace.verySlow.rawValue),
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
                                SCNAction.rotateBy(x: 0, y: 0, z: -0.08, duration: 0.025),
                                SCNAction.rotateBy(x: 0, y: 0, z:  0.16, duration: 0.050),
                                SCNAction.rotateBy(x: 0, y: 0, z: -0.08, duration: 0.025),
                                ]),
                            count: 3),
                        SCNAction.wait(duration: [1.0, 2.0, 3.0].random),
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
