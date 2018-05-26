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

final class HeroBlocks: MiniGame {
    static var title = "Super-Hero blocks!"
    var uivc: UIViewController = UIVC()

    class UIVC: UIViewController {
        var sceneView: SCNView!
        
        override func viewDidAppear(_ animated: Bool) {
            let effect = UIBlurEffect(style: .light)
            let effectView = UIVisualEffectView(effect: effect)
            effectView.frame = view.frame
            view.addSubview(effectView)
            
            let scene = HeroBlocks.Scene()
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
        case CaptainAmerica = 0
        case HawkEye        = 1
        case IronMan        = 2
        case Hulk           = 3
        case Thor           = 4
        case BlackWidow     = 5
        
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
            switch self {
            case .CaptainAmerica:   return #imageLiteral(resourceName: "Hero_CaptainAmerica")
            case .HawkEye:          return #imageLiteral(resourceName: "Hero_HawkEye")
            case .IronMan:          return #imageLiteral(resourceName: "Hero_IronMan")
            case .Hulk:             return #imageLiteral(resourceName: "Hero_Hulk")
            case .Thor:             return #imageLiteral(resourceName: "Hero_Thor")
            case .BlackWidow:       return #imageLiteral(resourceName: "Hero_BlackWidow")
            }
        }
        
        var sound: URL {
            switch self {
            case .CaptainAmerica:   return Catalog.sound(from: "HeroBlocks_CaptainAmerica.mp3")
            case .HawkEye:          return Catalog.sound(from: "HeroBlocks_HawkEye.mp3")
            case .IronMan:          return Catalog.sound(from: "HeroBlocks_IronMan.mp3")
            case .Hulk:             return Catalog.sound(from: "HeroBlocks_Hulk.mp3")
            case .Thor:             return Catalog.sound(from: "HeroBlocks_Thor.mp3")
            case .BlackWidow:       return Catalog.sound(from: "HeroBlocks_BlackWidow.mp3")
            }
        }
    }
    
    static var RotateClick          = Catalog.sound(from: "HeroBlocks_RotateClick.mp3")
    static var AvengersAssemble     = Catalog.sound(from: "HeroBlocks_AvengersAssemble.mp3")
    static var ChooseAnAvenger      = Catalog.sound(from: "HeroBlocks_ChooseAnAvenger.mp3")

    class Scene: SCNScene {
        var blocks: [Block] = []

        override init() {
            super.init()
            
            let camera = SCNNode()
            camera.camera = SCNCamera()
            camera.position = SCNVector3(x: 0, y: 0, z: 100)
            rootNode.addChildNode(camera)

            let box = SCNBox(width: 10.0, height: 10.0, length: 10.0, chamferRadius: 1)
            
            box.materials = Hero.all.map {
                let material = SCNMaterial()
                material.diffuse.contents = $0.image
                return material
            }
            
            let yDest:  [Float] = [-3.0, -1.0, 1.0, 3.0].map { $0 * Float(box.height) }
            
            AudioPlayer.play(AvengersAssemble)
            for i in 0...3 {
                let block = Block(geometry: box)
                block.position = SCNVector3(x: 0, y: 0, z: 100.0)

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 * Double(i)) {
                    block.runAction(SCNAction.move(to: SCNVector3(x: 0, y: yDest[i], z: 20), duration: 5.0))
                    block.entice()
                }

                rootNode.addChildNode(block)
                blocks.append(block)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 11.0) {
                AudioPlayer.play(ChooseAnAvenger)
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
                while true {
                    let rnd = Hero.all.random
                    if rnd != block.visible {
                        block.show(rnd)
                        break
                    }
                }
            }
        }
    }

    class Block: SCNNode {
        var visible: Hero = .CaptainAmerica
        
        enum Pace: TimeInterval {
            case fastPace     = 0.125
            case normalPace   = 0.25
            case slowPace     = 0.50
            case verySlowPace = 3.0
        }
        
        init(geometry: SCNGeometry?) {
            super.init()
            self.geometry = geometry
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func show(_ hero: Hero, at pace: Pace = .normalPace) {
            removeAllActions()
            
            if hero != visible {
                let rot = hero.rotation
                AudioPlayer.play(RotateClick)
                runAction(SCNAction.rotateTo(x: rot.x, y: rot.y, z: 0, duration: pace.rawValue)) {
                    AudioPlayer.play(hero.sound)
                }
                visible = hero
            }
        }
        
        func entice() {
            let visible = Hero.all.random
            let rot = visible.rotation
            runAction(
                SCNAction.sequence([
                    SCNAction.rotateTo(x: rot.x, y: rot.y, z: 0, duration: Pace.verySlowPace.rawValue),
                    SCNAction.repeatForever(SCNAction.sequence([
                            SCNAction.rotateBy(x: 0, y: 0, z: -0.08, duration: 0.025),
                            SCNAction.rotateBy(x: 0, y: 0, z:  0.16, duration: 0.050),
                            SCNAction.rotateBy(x: 0, y: 0, z: -0.08, duration: 0.025),
                            SCNAction.wait(duration: [0.25, 0.50, 0.75].random),
                            ])),
                ])
            )

        }
    }
}
