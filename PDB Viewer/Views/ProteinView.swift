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

struct ProteinView: View {
    var scene: SCNScene? {
        SCNScene(named: "art.scnassets/ship.scn")!
    }

    var cameraNode: SCNNode? {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 2)
        return cameraNode
    }

    var body: some View {
        SceneView(
            scene: scene,
            pointOfView: cameraNode,
            options: [
                .allowsCameraControl
            ]
        )
        .background(Color.black)
        .onDrop(of: [.data], delegate: ImportDroppedFiles())
        .edgesIgnoringSafeArea([.top, .bottom])
    }
    
}

struct ProteinView_Previews: PreviewProvider {
    static var previews: some View {
        ProteinView()
    }
}
