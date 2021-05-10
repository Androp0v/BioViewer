//
//  ProteinSceneView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/5/21.
//

import SceneKit
import SwiftUI
import UIKit

struct ProteinSceneView: UIViewRepresentable {

    let sceneView = SCNView(frame: .zero)

    @Binding var scene: SCNScene
    @Binding var sceneDelegate: ProteinViewSceneDelegate

    func makeUIView(context: Context) -> SCNView {
        sceneView.scene = scene
        sceneView.delegate = self.sceneDelegate
        sceneView.allowsCameraControl = true
        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {

    }
}

struct ProteinSceneView_Previews: PreviewProvider {
    static var previews: some View {
        ProteinSceneView(scene: .constant(SCNScene()),
                         sceneDelegate: .constant(ProteinViewSceneDelegate())
        )
    }
}
