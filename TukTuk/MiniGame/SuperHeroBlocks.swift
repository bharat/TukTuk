//
//  SuperHeroBlocks.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/14/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

 class SuperHeroBlocks: MiniGame {
    static var title = "Super-Hero blocks!"

    required init() {
    }

    func vc() -> UIViewController {
        return SuperHeroBlocksUIViewController()
    }
    
    class SuperHeroBlocksUIViewController: UIViewController {
        var sceneView: SCNView!
        
        override func viewDidAppear(_ animated: Bool) {
            let effect = UIBlurEffect(style: .light)
            let effectView = UIVisualEffectView(effect: effect)
            effectView.frame = view.frame
            view.addSubview(effectView)
            
            let scene = HeroScene()
            sceneView = SCNView(frame: view.frame)
            sceneView.backgroundColor = UIColor.lightGray
            sceneView.autoenablesDefaultLighting = true
            sceneView.allowsCameraControl = false
            sceneView.scene = scene
            sceneView.gestureRecognizers = [
                UITapGestureRecognizer(target: scene, action: #selector(scene.tapHeroBlock(gesture:)))
            ]
            
            effectView.contentView.addSubview(sceneView)
        }
    }

    enum Hero: Int {
        case Spiderman      = 0
        case Batman         = 1
        case IronMan        = 2
        case CaptainAmerica = 3
        case Hulk           = 4
        case Flash          = 5
        
        static var all: [Hero]  = [.Spiderman, .Batman, .IronMan, .CaptainAmerica, .Hulk, .Flash]
        
        var rotation: (x: CGFloat, y: CGFloat) {
            switch self {
            case .Spiderman:        return (x: 0.0,       y: 0.0     )
            case .Batman:           return (x: 0.0,       y: .pi / -2)
            case .IronMan:          return (x: 0.0,       y: .pi     )
            case .CaptainAmerica:   return (x: 0.0,       y: .pi / 2 )
            case .Hulk:             return (x: .pi / 2,   y: 0.0     )
            case .Flash:            return (x: .pi / -2,  y: 0.0     )
            }
        }
        
        var image: UIImage? {
            var (x, y) = (0, 0)
            switch self {
            case .Spiderman:        (x, y) = (3,   28 )
            case .Batman:           (x, y) = (185, 20 )
            case .IronMan:          (x, y) = (186, 264)
            case .CaptainAmerica:   (x, y) = (380, 269)
            case .Hulk:             (x, y) = (0,   525)
            case .Flash:            (x, y) = (381, 516)
            }
            
            return UIImage(named: "hero_faces")?.crop(to: CGRect(x: x, y: y, width: 200, height: 200))
        }
    }
    
    class HeroScene: SCNScene {
        var blocks: [Block] = []

        override init() {
            super.init()
            
            let camera = SCNNode()
            camera.camera = SCNCamera()
            camera.position = SCNVector3(x: 5, y: -50, z: 125)
            rootNode.addChildNode(camera)

            let box = SCNBox(width: 10.0, height: 10.0, length: 10.0, chamferRadius: 1)
            
            box.materials = Hero.all.map {
                let material = SCNMaterial()
                material.diffuse.contents = $0.image
                return material
            }
            
            for yLoc in ([-3.0, -1.0, 1.0, 3.0].map { $0 * Float(box.height) }) {
                let hero = Block(geometry: box)
                hero.position = SCNVector3(x: 0, y: yLoc, z: 20)
                rootNode.addChildNode(hero)
                blocks.append(hero)
            }
            
            camera.runAction(SCNAction.move(to: SCNVector3(x: 0, y: 0, z: 100), duration: 2.0))

            // For some reason, putting this in the camera.runAction() completion doesn't work
            // The code fires, but the nodes don't run the animation until I click them.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.blocks.forEach { $0.entice() }
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
                while block.show(Hero.all.random) == false { }
            }
        }
    }

    class Block: SCNNode {
        var visible: Hero = .Spiderman
        
        enum Pace: TimeInterval {
            case fastPace   = 0.125
            case normalPace = 0.25
            case slowPace   = 0.50
        }
        
        init(geometry: SCNGeometry?) {
            super.init()
            self.geometry = geometry
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func show(_ hero: Hero, at pace: Pace = .normalPace) -> Bool {
            removeAllActions()
            
            if hero != visible {
                let rot = hero.rotation
                runAction(SCNAction.rotateTo(x: rot.x, y: rot.y, z: 0, duration: pace.rawValue))
                visible = hero
                return true
            }
            
            return false
        }
        
        func entice() {
            let visible = Hero.all.random
            let rot = visible.rotation
            runAction(
                SCNAction.sequence([
                    SCNAction.rotateTo(x: rot.x, y: rot.y, z: 0, duration: Pace.slowPace.rawValue),
                    SCNAction.repeatForever(SCNAction.sequence([
                            SCNAction.rotateBy(x: 0, y: 0, z: -0.08, duration: 0.025),
                            SCNAction.rotateBy(x: 0, y: 0, z:  0.16, duration: 0.050),
                            SCNAction.rotateBy(x: 0, y: 0, z: -0.08, duration: 0.025),
                            SCNAction.wait(duration: [0.5, 0.75, 1.0].random),
                            ])),
                ])
            )

        }
    }
}
