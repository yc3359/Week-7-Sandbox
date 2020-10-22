//
//  ViewController.swift
//  PlaneDetect
//
//  Created by Nien Lam on 10/8/20.
//  Modified by Ying C on 10/21/20.

import UIKit
import ARKit
import RealityKit
import Combine

class ViewController: UIViewController {

    @IBOutlet weak var myARView: ARView!
    @IBOutlet weak var interfaceView: InterfaceView!

    // Root entity of Reality Composer Scene.
    var myEntities: Entity!
    
    // Anchor at position [0, 0, 0].
    var originAnchor: AnchorEntity!

    // Anchor tracks camera point of view.
    var cameraAnchor: AnchorEntity!

    // Cursor entity on horizontal or vertical surfaces.
    var cursor: Entity!
    
    // For callback methods.
    var subscriptions = Set<AnyCancellable>()

    // Base plane entity.
    var basePlane: Entity!
    
    // Base box entity.
    var baseBox: Entity!
    
    var baseMap: Entity!

    // Reference to array of box entities.
    var arrayOfBoxEntities = [Entity]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load root entity from Reality Composer Project.
        myEntities = try! Experience.loadMyEntities()
        
        // Create and add origin anchor.
        originAnchor = AnchorEntity(world: float4x4(1))
        myARView.scene.addAnchor(originAnchor)
        
        // Create and add camera anchor.
        cameraAnchor = AnchorEntity(.camera)
        myARView.scene.addAnchor(cameraAnchor)

        // Add cursor. Tracks on horizontal and vertical planes.
        cursor = Guides.makeCursor()
        originAnchor.addChild(cursor)
        
        // Called every frame.
        myARView.scene.subscribe(to: SceneEvents.Update.self) { event in
            // Update cursor position.
            self.updateCursor()
        }.store(in: &subscriptions)


        //
        // Adding green base plane entity. ///////////////////////////////////////////////////
        
        // Create green material
        let greenMaterial = SimpleMaterial(color: UIColor.white.withAlphaComponent(0),
                                           isMetallic: false)
        // Create plane mesh.
        let plane = MeshResource.generatePlane(width: 0, depth: 0)

        // Create an entity from mesh and material
        basePlane = ModelEntity(mesh: plane, materials: [greenMaterial])

        // Add base to origin anchor.
        originAnchor.addChild(basePlane)


        //
        // Adding green base plane entity to base. //////////////////////////////////////////
        
        // Add buildingMod to top of plane.
        baseBox = myEntities.findEntity(named: "BuildingMod")!.clone(recursive: true)
        baseBox.transform.translation = [0,0,0]
        
        //Add wsqMap to top of plane.
        baseMap = myEntities.findEntity(named: "WsqMap")!.clone(recursive: true)
        baseMap.transform.translation = [0,0,0]

        // Move box up half the size of box height.
//        baseBox.position.y = 0.05

        // Important: Adding bold base to entity.
        basePlane.addChild(baseBox)
        basePlane.addChild(baseMap)
    
        // Add box to array for reference.
        arrayOfBoxEntities.append(baseBox)
        arrayOfBoxEntities.append(baseMap)
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Running on device.
        #if !targetEnvironment(simulator)
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal, .vertical]
            myARView.session.run(configuration)
        #endif
    }

    private func updateCursor() {
        // Raycast to get cursor position.
        let results = myARView.raycast(from: self.view.center,
                                       allowing: .existingPlaneGeometry,
                                       alignment: .any)
            
        // Move cursor to position if hitting plane.
        if let result = results.first {
            cursor.isEnabled = true
            cursor.move(to: result.worldTransform, relativeTo: originAnchor)
        } else {
            cursor.isEnabled = false
        }
    }

    
    @IBAction func didTapMoveToCursorButton(_ sender: Any) {
        //
        // Animation function. ///////////////////////////////////////////////////////////
        
        // Timing functions:
        //
        // .linear
        // .easeIn
        // .easeOut
        // .easeInOut
        basePlane.move(to: cursor.transform,
                       relativeTo: originAnchor,
                       duration: 0.35,
                       timingFunction: .linear)
    }

    @IBAction func didTapMoveRightButton(_ sender: Any) {
        // Create new target transform.
        cameraAnchor = AnchorEntity(.camera)
        myARView.scene.addAnchor(cameraAnchor)
        
        
        var newTransform = Transform()
        newTransform.translation = SIMD3(0, -0.01, 0)

        // Be sure to set correct relativeTo entity.
        basePlane.move(to: newTransform,
                       relativeTo: cameraAnchor,
                       duration: 0.35,
                       timingFunction: .easeInOut)
    }

    @IBAction func didTapRotate(_ sender: Any) {
        // Create new target transform.
        // Rotate along the z axis 90 degrees.
        var newTransform = Transform()
//        newTransform.rotation = simd_quatf(angle: Float.pi / 2, axis: [0, 0.5, 0])
        
        let radians = Float.pi / 4
        newTransform.rotation *= simd_quatf(angle: radians, axis: SIMD3<Float>(0, 1, 0))

        // Be sure to set correct relativeTo entity.
        let baseBox = arrayOfBoxEntities[0]
        baseBox.move(to: newTransform,
                     relativeTo: baseBox,
                     duration: 0.35,
                     timingFunction: .easeInOut)
        
        let baseMap = arrayOfBoxEntities[1]
        baseMap.move(to: newTransform,
                     relativeTo: baseMap,
                     duration: 0.35,
                     timingFunction: .easeInOut)
    }

    @IBAction func didTapAddChild(_ sender: UIButton) {
        // Clone new box.
//        let buildingMod = myEntities.findEntity(named: "BuildingMod")!.clone(recursive: true)
        if baseMap.isEnabled == true {
            baseMap.isEnabled = false
            sender.setTitle("Enable Map", for: .normal)
        } else {
            baseMap.isEnabled = true
            sender.setTitle("Disable Map", for: .normal)
        }
        
        // Move box up slightly.
//        buildingMod.transform.translation = [0, 0, 0]

        // Add buildingMod to last array entity element.
//        let lastEntityElement = arrayOfBoxEntities.last
//        lastEntityElement?.addChild(buildingMod)

        // Add buildingMod to array for reference.
//        arrayOfBoxEntities.append(buildingMod)
    }
    
    @IBAction func didUpdateSlider(_ sender: UISlider) {
        let scale = sender.value
        arrayOfBoxEntities[0].transform.scale = [Float(scale),Float(scale),Float(scale)]
        arrayOfBoxEntities[1].transform.scale = [Float(scale),Float(scale),Float(scale)]

        // Rotate just the first entity.
//        arrayOfBoxEntities[0].transform.rotation = simd_quatf(angle: angle, axis: [0, 0, 1])

        /*
        // Rotate all entities on the z axis.
        for entity in arrayOfBoxEntities {
            entity.transform.rotation = simd_quatf(angle: angle, axis: [0, 0, 1])
        }
        */
    }
}
