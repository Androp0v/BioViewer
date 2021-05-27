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
    var proteinToggleCancellable: AnyCancellable?
    var surfaceToggleCancellable: AnyCancellable?

    var cameraNode: SCNNode
    var lightNode: SCNNode
    var proteinRootNode: SCNNode
    var proteinSurfaceRootNode: SCNNode

    @Published var dataSource: ProteinViewDataSource

    let dropDelegate: ImportDroppedFilesDelegate

    // Status properties
    @Published var statusText: String
    @Published var statusRunning: Bool
    @Published var progress: Float?

    @Published var proteinCount: Int = 0
    @Published var totalAtomCount: Int = 0

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

        // Setup camera node
        self.cameraNode = SCNNode()
        self.cameraNode.position = SCNVector3(x: 0, y: 0, z: 300)
        scene.rootNode.addChildNode(cameraNode)

        // Setup initial camera camera (will be hijacked by SceneKit
        // because the option allowsCameraControl is set to true,
        // generating a new camera in this position).
        self.cameraNode.camera = SCNCamera()
        self.cameraNode.camera?.zFar = 5000

        // Create and add a light to the scene
        self.lightNode = SCNNode()
        self.lightNode.light = SCNLight()
        // TO-DO: .omni lights can't cast shadows
        self.lightNode.light?.type = .omni
        self.lightNode.position = SCNVector3(x: 300, y: 300, z: 0)
        self.cameraNode.addChildNode(self.lightNode)

        // Create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)

        // Create protein node to attach proteins
        self.proteinRootNode = SCNNode()
        self.proteinRootNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(proteinRootNode)

        // Create protein surface node to attach protein surfaces
        self.proteinSurfaceRootNode = SCNNode()
        self.proteinSurfaceRootNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(proteinSurfaceRootNode)

        // Set scene background color (listening for changes). Can't be
        // done through a @Published variable since we're interfacind
        // with a UIKit view (SCNView).
        self.sceneBackgroundColorCancellable = sceneDelegate.$sceneBackground.sink { [weak self] color in
            // This might reset the scene camera position, unsure why
            self!.scene.background.contents = UIColor(color)
        }

        self.proteinToggleCancellable = sceneDelegate.$showProtein.sink { [weak self] state in
            self?.proteinRootNode.isHidden = !state
        }

        // Set the visibility of the protein surface node (listening for
        // changes). Dispatch on background thread since this can be
        // computationally expensive if the surface needs to be computed.
        self.surfaceToggleCancellable = sceneDelegate.$showSurface.sink { [weak self] state in
            DispatchQueue.global(qos: .userInitiated).async {
                if state == true {
                    // If the surface should be shown
                    self?.proteinSurfaceRootNode.isHidden = false
                    // Compute the surface if it hadn't been computed before
                    if self?.proteinSurfaceRootNode.childNodes.count == 0 {
                        guard let protein = dataSource.proteins.first else { return }
                        MetalScheduler.shared.createSASPoints(protein: protein,
                                                              sceneDelegate: sceneDelegate)
                    }
                } else {
                    // Hide the node if required
                    self?.proteinSurfaceRootNode.isHidden = true
                }
            }
        }

        // Pass reference to ProteinViewModel to delegates and datasources
        self.dataSource.proteinViewModel = self
        self.sceneDelegate.proteinViewModel = self
        self.dropDelegate.proteinViewModel = self
    }

    // MARK: - Public functions

    func removeAllProteins() {
        // TO-DO: Handle proteins added to the datasource but not yet to
        // the scene.
        self.proteinRootNode.enumerateChildNodes( { node, _  in
            node.removeFromParentNode()
        })
        self.dataSource.removeAllProteinsFromDatasource()
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
