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
        sceneView.pointOfView = parent.proteinViewModel.cameraNode
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
        var povObserver: NSKeyValueObservation?

        init(_ control: ProteinSceneView) {
            self.control = control
            let cameraController = control.sceneView.defaultCameraController
            povObserver = cameraController.observe(\.pointOfView, options: [.new]) {  (cameraController, change) in
                if let newPov = cameraController.pointOfView {
                    // Whenever SceneKit creates a new pointOfView node and attaches
                    // the camera to it, recover the camera light and attach it as well.
                    control.parent.proteinViewModel.lightNode.removeFromParentNode()
                    newPov.addChildNode(control.parent.proteinViewModel.lightNode)
                }
            }
        }

        func renderer(_ renderer: SCNSceneRenderer,
               updateAtTime time: TimeInterval) {
        }

        @objc func sceneViewTapRecognizer(gestureReconizer: UITapGestureRecognizer) {
            control.handleTapOutside(gestureRecognizer: gestureReconizer)
        }

    }

    // MARK: - Private functions

    /// Handle the tap in the ```ProteinSceneView``` struct, where ```sceneView```
    /// is available.
    func handleTapOutside(gestureRecognizer: UITapGestureRecognizer) {
        let position = gestureRecognizer.location(in: sceneView)
        let hitResults = sceneView.hitTest(position, options: [:])
        // TO-DO: This should return the node being hit so the proper part
        // of the sequence can be shown in the protein sequence view widget
        // TO-DO: This feels weird on-device because the atoms are tiny and
        // taps may not exactly be on top of an atom. Consider sampling for
        // close locations to the original tap for nearby atoms if no hit
        // is registered.
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
