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

    // MARK: - Initialization

    let sceneView = SCNView(frame: .zero)

    public var parent: ProteinView
    @Binding var scene: SCNScene
    @Binding var sceneDelegate: ProteinViewSceneDelegate

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> SCNView {
        sceneView.scene = scene
        sceneView.delegate = self.sceneDelegate
        sceneView.allowsCameraControl = true
        let tapRecognizer = UITapGestureRecognizer(target: context.coordinator,
                                                   action: #selector(Coordinator.sceneViewTapRecognizer(gestureReconizer:)))
        sceneView.addGestureRecognizer(tapRecognizer)
        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {

    }

    // MARK: - Coordinator

    class Coordinator: NSObject {
        var control: ProteinSceneView

        init(_ control: ProteinSceneView) {
            self.control = control
        }

        func renderer(_ renderer: SCNSceneRenderer,
               updateAtTime time: TimeInterval) {
        }

        @objc func sceneViewTapRecognizer(gestureReconizer: UITapGestureRecognizer) {
            control.handleTapOutside(gestureRecognizer: gestureReconizer)
        }

    }

    // MARK: - Private functions

    func handleTapOutside(gestureRecognizer: UITapGestureRecognizer) {
        let position = gestureRecognizer.location(in: sceneView)
        let hitResults = sceneView.hitTest(position, options: [:])
        if hitResults.count > 0 {
            parent.didTapScene(nodeHit: true)
        } else {
            parent.didTapScene(nodeHit: false)
        }
    }


}

struct ProteinSceneView_Previews: PreviewProvider {
    static var previews: some View {
        ProteinSceneView(parent: ProteinView(),
                         scene: .constant(SCNScene()),
                         sceneDelegate: .constant(ProteinViewSceneDelegate())
        )
    }
}
