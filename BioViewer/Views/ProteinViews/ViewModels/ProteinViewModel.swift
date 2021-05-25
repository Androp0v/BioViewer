//
//  ProteinViewModel.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 13/5/21.
//

import Combine
import Foundation
import SceneKit

class ProteinViewModel: ObservableObject {

    // MARK: - Properties

    @Published var scene: SCNScene
    @Published var sceneDelegate: ProteinViewSceneDelegate
    var sceneBackgroundColorCancellable: AnyCancellable?
    var cameraNode: SCNNode

    @Published var dataSource: ProteinViewDataSource

    let dropDelegate: ImportDroppedFilesDelegate

    // Status properties
    @Published var statusText: String
    @Published var statusRunning: Bool
    @Published var progress: Float?

    // MARK: - Initialization

    init() {
        // Open SceneKit scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        self.scene = scene

        // Setup scene delegate and datasource
        let sceneDelegate = ProteinViewSceneDelegate()
        let dataSource = ProteinViewDataSource()
        self.sceneDelegate = sceneDelegate
        self.dataSource = dataSource
        sceneDelegate.scene = scene

        // Setup drop delegate
        self.dropDelegate = ImportDroppedFilesDelegate()

        // Setup view status
        self.statusText = "Idle"
        self.statusRunning = false

        // Setup camera
        self.cameraNode = SCNNode()
        self.cameraNode.camera = SCNCamera()
        self.cameraNode.position = SCNVector3(x: 0, y: 0, z: 300)
        self.cameraNode.camera?.zFar = 5000
        scene.rootNode.addChildNode(cameraNode)

        // Create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 300, z: 0)
        scene.rootNode.addChildNode(lightNode)

        // Create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)

        // Set scene background color (listening for changes). Can't be
        // done through a @Published variable since we're interfacind
        // with a UIKit view (SCNView).
        self.sceneBackgroundColorCancellable = sceneDelegate.$sceneBackground.sink { [weak self] color in
            // This might reset the scene camera position, unsure why
            self!.scene.background.contents = UIColor(color)
        }

        // Pass reference to ProteinViewModel to delegates and datasources
        self.dataSource.proteinViewModel = self
        self.sceneDelegate.proteinViewModel = self
        self.dropDelegate.proteinViewModel = self
    }

    // MARK: - Status handling

    func statusUpdate(statusText: String) {
        DispatchQueue.main.sync {
            self.statusText = statusText
            self.statusRunning = true
        }
    }

    func statusProgress(progress: Float) {
        DispatchQueue.main.sync {
            self.progress = progress
        }
    }

    func statusFinished() {
        DispatchQueue.main.sync {
            self.statusText = "Idle"
            self.statusRunning = false
            self.progress = nil
        }
    }
}