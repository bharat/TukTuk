//
//  SpellyBlocks.swift
//  TukTuk
//
//  Created by Bharat Mediratta on 6/1/18.
//  Copyright © 2018 Menalto. All rights reserved.
//

import Foundation
import UIKit
import ARKit
import SceneKit

final class SpellyBlocks: MiniGame {
    static var title = "Spelly blocks!"
    var uivc: UIViewController = UIVC()

    class UIVC: UIViewController {
        var sceneView: ARSCNView!
        var scene = SpellyBlocks.Scene()

        override func viewDidLoad() {
            let effect = UIBlurEffect(style: .light)
            let effectView = UIVisualEffectView(effect: effect)
            effectView.frame = view.frame
            view.addSubview(effectView)

            scene.completion = {
                self.dismiss(animated: true)
            }

            sceneView = ARSCNView(frame: view.frame)
            sceneView.scene = scene
            sceneView.backgroundColor = .black
            sceneView.autoenablesDefaultLighting = false
            sceneView.allowsCameraControl = false
            effectView.contentView.addSubview(sceneView)

            sceneView.gestureRecognizers = [
                UITapGestureRecognizer(target: self, action: #selector(didTapScreen(recognizer:)))
                ]

            scene.start() {
            }
        }

        @objc func didTapScreen(recognizer: UITapGestureRecognizer) {
            if let camera = sceneView.session.currentFrame?.camera {
                let tapLocation = recognizer.location(in: sceneView)
                let hitTestResults = sceneView.hitTest(tapLocation)

                var translation = matrix_identity_float4x4
                translation.columns.3.z = -5.0
                let transform = camera.transform * translation
                let position = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
                scene.addSphere(position: position)
            }
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
            camera.camera?.zFar = 400.0
            camera.position = SCNVector3(x: 0, y: 0, z: 100)
            rootNode.addChildNode(camera)

            let omniLight = SCNNode()
            omniLight.light = SCNLight()
            omniLight.light!.type = .omni
            omniLight.light!.color = UIColor(white: 1.0, alpha: 1.0)
            omniLight.position = SCNVector3Make(0, 0, 100)
            rootNode.addChildNode(omniLight)
        }

        func start(completion: @escaping () -> ()) {
            completion()
        }

        func addSphere(position: SCNVector3) {
            let sphere = SCNSphere(radius: 10)

            [#imageLiteral(resourceName: "FaceBalls_1"), #imageLiteral(resourceName: "FaceBalls_2"), #imageLiteral(resourceName: "FaceBalls_3")].forEach {
                sphere.materials.append(SCNMaterial())
                sphere.materials.last?.diffuse.contents = $0
            }

            let node = SCNNode(geometry: sphere)
            node.position = position
            self.rootNode.addChildNode(node)
        }

    }
}
