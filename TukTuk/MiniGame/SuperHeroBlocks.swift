 //
//  Blocks.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 5/14/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

 class SuperHeroBlocks: MiniGame {
    static var title = "Super-hero blocks!"

    required init() {
    }

    func vc() -> UIViewController {
        return SuperHeroBlocksUIViewController()
    }

    class SuperHeroBlocksUIViewController: UIViewController {
        var heroBlocks: [SCNNode] = []
        var sceneView: SCNView!

        override func viewDidAppear(_ animated: Bool) {
            let effect = UIBlurEffect(style: .light)
            let effectView = UIVisualEffectView(effect: effect)
            effectView.frame = view.frame
            view.addSubview(effectView)

            let scene = Scene()
            heroBlocks = scene.addHeroBlocks()

            sceneView = SCNView(frame: view.frame)
            sceneView.backgroundColor = UIColor.lightGray
            sceneView.autoenablesDefaultLighting = true
            sceneView.allowsCameraControl = false
            sceneView.scene = scene
            sceneView.gestureRecognizers = [
                UITapGestureRecognizer(target: self, action: #selector(tapHeroBlock(gesture:)))
            ]

            effectView.contentView.addSubview(sceneView)
        }

        @objc func tapHeroBlock(gesture: UITapGestureRecognizer) {
            let point = gesture.location(in: sceneView)
            let hits = sceneView.hitTest(point, options: nil)

            if let block = hits.first?.node as? Block {
                block.stopWiggling()
                block.showNextFace()
            }
        }
    }
    
    struct Hero {
        
    }
    
    class Block: SCNNode {
        var visibleFace = 0
        
        init(geometry: SCNGeometry?) {
            super.init()
            self.geometry = geometry
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func showNextFace() {
            visibleFace = (visibleFace + 1) % 6
            show(face: visibleFace)
        }
        
        func show(face: Int) {
            let rot = [
                [0.0,       0.0,       0.0],  // Spiderman
                [0.0,       .pi / -2,  0.0],  // Batman
                [0.0,       .pi,       0.0],  // Iron Man
                [0.0,       .pi / 2,   0.0],  // Captain America
                [.pi / 2,   0.0,       0.0],  // Hulk
                [.pi / -2,  0.0,       0.0],  // Flash
                ][face]

            runAction(SCNAction.rotateTo(x: CGFloat(rot[0]), y: CGFloat(rot[1]), z: CGFloat(rot[2]), duration: 0.25))
        }
        
        func stopWiggling() {
            removeAllActions()
        }
        
        func wiggle() {
            runAction(SCNAction.repeatForever(
                SCNAction.sequence([
                    SCNAction.rotateBy(x: 0, y: 0, z: -0.08, duration: 0.025),
                    SCNAction.rotateBy(x: 0, y: 0, z:  0.16, duration: 0.050),
                    SCNAction.rotateBy(x: 0, y: 0, z: -0.08, duration: 0.025),
                ])))
        }
    }

    class Scene: SCNScene {
        override init() {
            super.init()

            let camera = SCNNode()
            camera.camera = SCNCamera()
            camera.position = SCNVector3(x: 5, y: -50, z: 125)
            camera.runAction(SCNAction.move(to: SCNVector3(x: 0, y: 0, z: 100), duration: 2.0))

            rootNode.addChildNode(camera)
        }

        required init(coder: NSCoder) {
            fatalError("Not yet implemented")
        }

        func addHeroBlocks() -> [Block] {
            let box = SCNBox(width: 10.0, height: 10.0, length: 10.0, chamferRadius: 1)

            box.materials = [
                CGRect(x: 3,   y: 28,  width: 200, height: 200),   // Spiderman
                CGRect(x: 185, y: 20,  width: 200, height: 200),   // Batman
                CGRect(x: 186, y: 264, width: 200, height: 200),   // Iron Man
                CGRect(x: 380, y: 269, width: 200, height: 200),   // Captain America
                CGRect(x: 0,   y: 525, width: 200, height: 200),   // Hulk
                CGRect(x: 381, y: 516, width: 200, height: 200),   // Flash
            ].map {
                let material = SCNMaterial()
                material.diffuse.contents = UIImage(named: "hero_faces")?.crop(to: $0)
                return material
            }

            var heroes: [Block] = []
            for yLoc in ([-3.0, -1.0, 1.0, 3.0].map { $0 * Float(box.height) }) {
                let hero = Block(geometry: box)
                hero.position = SCNVector3(x: 0, y: yLoc, z: 20)
                rootNode.addChildNode(hero)
                heroes.append(hero)
                
                hero.show(face: 0)
                hero.wiggle()
            }
            return heroes
        }
    }
}
