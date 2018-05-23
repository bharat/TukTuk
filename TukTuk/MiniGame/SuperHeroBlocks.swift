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

    var heroBlocks: [SCNNode] = []
    var sceneView: SCNView!

    required init() {
    }

    func play(on view: UIView) {
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
            UITapGestureRecognizer(target: self, action: #selector(tapHeroBlock(gesture:))),
            UIPanGestureRecognizer(target: self, action: #selector(panHeroBlock(gesture:)))
        ]

        effectView.contentView.addSubview(sceneView)
    }

    @objc func tapHeroBlock(gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: sceneView)
        let hits = sceneView.hitTest(point, options: nil)

        if let node = hits.first?.node {
            // Stop spinning
            node.removeAllActions()
        }
    }

    @objc func panHeroBlock(gesture: UIPanGestureRecognizer) {
        let point = gesture.location(in: sceneView)
        let hits = sceneView.hitTest(point, options: nil)

        if let node = hits.first?.node {
            // Stop spinning
            node.removeAllActions()

            let currentPivot = node.pivot
            let changePivot = SCNMatrix4Invert(node.transform)
            node.pivot = SCNMatrix4Mult(changePivot, currentPivot)
            node.transform = SCNMatrix4Identity
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

        func addHeroBlocks() -> [SCNNode] {
            let box = SCNBox(width: 10.0, height: 10.0, length: 10.0, chamferRadius: 1)

            box.materials = [
                CGRect(x: 3,   y: 28,  width: 200, height: 200),   // Spiderman
                CGRect(x: 185, y: 20,  width: 200, height: 200),   // Batman
                CGRect(x: 186, y: 264, width: 200, height: 200),   // Iron Man
                CGRect(x: 380, y: 269, width: 200, height: 200),   // Captain America
                CGRect(x: 0,   y: 525, width: 200, height: 200),   // Hulk
                CGRect(x: 381, y: 516, width: 200, height: 200)    // Flash
            ].map {
                let material = SCNMaterial()
                material.diffuse.contents = UIImage(named: "hero_faces")?.crop(to: $0)
                return material
            }

            var heroes: [SCNNode] = []
            for yLoc in ([-3.0, -1.0, 1.0, 3.0].map { $0 * Float(box.height) }) {
                let hero = SCNNode(geometry: box)
                hero.position = SCNVector3(x: 0, y: yLoc, z: 20)
                rootNode.addChildNode(hero)

                hero.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: [-1.1, 1.1].random!, y: [-1.2, 1.2].random!, z: [-1.3, 1.3].random!, duration: [1.5, 2.0, 2.5].random!)))

                heroes.append(hero)
            }
            return heroes
        }
    }
}
