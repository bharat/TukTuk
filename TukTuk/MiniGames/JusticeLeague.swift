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

extension URL {
    static let JL_Start       = Bundle.sound("JusticeLeague/ComeTogether.mp3")
    static let JL_Choose      = Bundle.sound("JusticeLeague/Choose.mp3")
    static let JL_Complete    = Bundle.sound("JusticeLeague/Tada.mp3")
}

final class JusticeLeague: MiniGame {
    static var title = "Justice League!"
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
        case Superman
        case Batman
        case WonderWoman
        case Cyborg
        case Flash
        case Aquaman

        static var all: [Hero]  = [.Superman, .Batman, .WonderWoman, .Cyborg, .Flash, .Aquaman]

        var rotation: (x: CGFloat, y: CGFloat) {
            switch self {
            case .Superman:      return (     0.0,  0.0     )
            case .Batman:        return (     0.0,  -.pi / 2)
            case .WonderWoman:   return (     0.0,   .pi    )
            case .Cyborg:        return (     0.0,   .pi / 2)
            case .Flash:         return ( .pi / 2,  0.0     )
            case .Aquaman:       return (-.pi / 2,  0.0     )
            }
        }

        var neighbor: (left: Hero, right: Hero, up: Hero, down: Hero) {
            switch self {
            case .Superman:    return (.Cyborg, .Batman, .Flash, .Aquaman)
            case .Batman:      return (.Superman, .WonderWoman, .Flash, .Aquaman)
            case .WonderWoman: return (.Batman, .Superman, .Flash, .Aquaman)
            case .Cyborg:      return (.WonderWoman, .Superman, .Flash, .Aquaman)
            case .Flash:       return (.Cyborg, .Batman, .WonderWoman, .Superman)
            case .Aquaman:     return (.Cyborg, .Batman, .Superman, .WonderWoman)
            }
        }

        var image: UIImage? {
            return UIImage(named: "JusticeLeague_\(rawValue)")
        }

        var sound: URL {
            return Bundle.sound("JusticeLeague/\(rawValue).mp3")
        }

        var video: URL {
            return Bundle.video("JusticeLeague/\(rawValue).mp4")
        }
    }

    class UIVC: UIViewController {
        override func viewDidLoad() {
            AudioPlayer.play(.JL_Start)

            let effect = UIBlurEffect(style: .light)
            let effectView = UIVisualEffectView(effect: effect)
            effectView.frame = view.frame
            view.addSubview(effectView)

            let scene = JusticeLeague.Scene()
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

        required init(coder: NSCoder) {
            fatalError("Not yet implemented")
        }

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
            let randomHeroes = Hero.all.shuffled()
            for (i, block) in blocks.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 * Double(i)) {
                    block.show(randomHeroes[i], pace: .verySlow)
                    block.runAction(SCNAction.move(to: SCNVector3(x: 0, y: yDest[i], z: 20), duration: Pace.verySlow.duration)) {
                    }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 9.0) {
                self.blocks.forEach {
                    $0.enticing = true
                }

                AudioPlayer.play(.JL_Choose)
                completion()
            }
        }

        var turnsRemaining = 50
        @objc func swipeBlock(gesture: UISwipeGestureRecognizer) {
            let sceneView = gesture.view as! SCNView
            let point = gesture.location(in: sceneView)
            let hits = sceneView.hitTest(point, options: nil)
            
            if let block = hits.first?.node as? Block {
                blocks.forEach { $0.enticing = false }

                if gesture.state == .ended {
                    var new: Hero
                    switch gesture.direction {
                    case .right:    new = block.hero.neighbor.left
                    case .left:     new = block.hero.neighbor.right
                    case .up:       new = block.hero.neighbor.down
                    case .down:     new = block.hero.neighbor.up
                    default:        new = .Superman
                    }

                    // Accelerate to the finish if it's taking too long
                    turnsRemaining -= 1
                    AudioPlayer.play(new.sound)
                    if turnsRemaining == 0 {
                        self.blocks.filter { $0 != block }.forEach {
                            $0.show(new)
                        }
                    }

                    block.show(new) {
                        // If they're all the same, we're ready for the next phase
                        if self.turnsRemaining == 0 || Set(self.blocks.map { $0.hero }).count == 1 {
                            DispatchQueue.main.async {
                                sceneView.gestureRecognizers?.forEach {
                                    $0.isEnabled = false
                                }
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + Pace.normal.duration) {
                                self.select(hero: self.blocks[0].hero, from: block)
                            }
                        }
                    }
                }
            }
        }
        
        func select(hero: Hero, from block: Block) {
            AudioPlayer.play(.JL_Complete)

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
        var hero: Hero = .Superman
        var enticing: Bool = false {
            didSet {
                if enticing && !oldValue {
                    enticeLoop()
                }
            }
        }
        
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
            let x = (Hero.Superman.rotation.x - hero.rotation.x + new.rotation.x)
            var y = (Hero.Superman.rotation.y - hero.rotation.y + new.rotation.y)

            // Avoid rotating over .pi, which would cause the rotation code to flip directions
            switch y {
            case _ where y < -.pi:  y = .pi / 2
            case _ where y > .pi:   y = -.pi / 2
            default:                ()
            }

            runAction(
                SCNAction.rotateBy(x: x, y: y, z: 0, duration: pace.duration),
                forKey: "show") {
                    self.hero = new
                    completion()
            }
        }

        func enticeLoop() {
            DispatchQueue.main.asyncAfter(deadline: .now() + [8, 9, 10, 11, 12].random) {
                // We use this approach instead of removeAction(forKey:) to avoid stopping
                // mid-action and leaving the block misaligned.
                if !self.enticing {
                    return
                }

                let dir: CGFloat = [1.0, -1.0].random
                self.runAction(
                    SCNAction.sequence([
                        SCNAction.rotateBy(x: 0, y: dir * -0.8, z: 0, duration: 0.5),
                        SCNAction.rotateBy(x: 0, y: dir *  0.8, z: 0, duration: 0.1),
                        SCNAction.rotateBy(x: 0, y: dir *  0.2, z: 0, duration: 0.05),
                        SCNAction.rotateBy(x: 0, y: dir * -0.4, z: 0, duration: 0.1),
                        SCNAction.rotateBy(x: 0, y: dir *  0.2, z: 0, duration: 0.05),
                        ])
                ) {
                    self.enticeLoop()
                }
            }
        }
    }
}
