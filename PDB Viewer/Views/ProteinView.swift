//
//  ContentView.swift
//  PDB Viewer
//
//  Created by Raúl Montón Pinillos on 4/5/21.
//

import SwiftUI
import SceneKit
import UniformTypeIdentifiers

import SwiftUI
import SceneKit
import UIKit

struct ProteinView: View {

    // MARK: - Properties
    private var scene: SCNScene
    private var sceneDelegate: ProteinViewSceneDelegate
    private var dropDelegate: ImportDroppedFilesDelegate
    private var cameraNode: SCNNode

    // MARK: - Initialization

    init() {

        // Open SceneKit scene
        self.scene = SCNScene(named: "art.scnassets/ship.scn")!

        // Setup scene delegate
        self.sceneDelegate = ProteinViewSceneDelegate()
        sceneDelegate.scene = scene

        // Setup drop delegate
        self.dropDelegate = ImportDroppedFilesDelegate(sceneDelegate: self.sceneDelegate)

        // Setup camera
        self.cameraNode = SCNNode()
        self.cameraNode.camera = SCNCamera()
        self.cameraNode.position = SCNVector3(x: 0, y: 0, z: 100)
        self.cameraNode.camera?.zFar = 1000
        scene.rootNode.addChildNode(cameraNode)

        // Create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 100, z: 0)
        scene.rootNode.addChildNode(lightNode)

        // Create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)

    }

    var body: some View {
        VStack{
            Rectangle()
                .frame(height: 20)
                .foregroundColor(Color(UIColor.systemBackground))
            SceneView(
                scene: scene,
                pointOfView: cameraNode,
                options: [
                    .autoenablesDefaultLighting,
                    .allowsCameraControl,
                ],
                delegate: sceneDelegate
            )
            .background(Color.black)
            .onDrop(of: [.data], delegate: dropDelegate)
            .navigationTitle("Protein view")
            .navigationBarTitleDisplayMode(.inline)
            .edgesIgnoringSafeArea([.top, .bottom])
        }
    }
    
}

struct ProteinView_Previews: PreviewProvider {
    static var previews: some View {
        ProteinView()
    }
}
