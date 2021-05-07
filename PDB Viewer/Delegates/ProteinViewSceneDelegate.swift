//
//  ProteinViewRendererDelegate.swift
//  PDB Viewer
//
//  Created by Raúl Montón Pinillos on 7/5/21.
//

import Foundation
import SceneKit
import SwiftUI

class ProteinViewSceneDelegate: NSObject, SCNSceneRendererDelegate {

    // MARK: - Properties

    public var scene: SCNScene?

    private var maxTargetFrameDuration: Int {
        // Get desired maximum time per frame in nanoseconds
        // based on the maximum screen refresh rate.
        var maxFramesPerSecond = UIScreen().maximumFramesPerSecond
        if maxFramesPerSecond == 0 {
            maxFramesPerSecond = 60
        }
        let frameTimeNanoseconds = 10*10*10*10*10*10*10*10*10 / maxFramesPerSecond
        return frameTimeNanoseconds
    }

    // MARK: - I/O

    public let serialQueue = DispatchQueue(label: "I/O queue", qos: .userInitiated)
    public var importObjects: Bool = false

    // MARK: - Protein loading
    private var proteinsToLoad: LoadingProtein?
    private var atomMaterial: SCNMaterial?
    private var proteinAxis: SCNNode?

    // MARK: - Functions

    /// Add protein to the current scene atom by atom.
    /// - Parameter atoms: Atom positions.
    func addProtein(atoms: [simd_float3], atomIdentifiers: [Int]) {

        // Atom material
        self.atomMaterial = SCNMaterial()
        self.atomMaterial?.diffuse.contents = UIColor.green
        self.atomMaterial?.lightingModel = .blinn
        self.atomMaterial?.reflective.contents = UIColor.green
        self.atomMaterial?.reflective.intensity = 1

        self.proteinAxis = SCNNode()
        self.proteinAxis?.position = SCNVector3(0,0,0)
        scene?.rootNode.addChildNode(proteinAxis!)

        // Mark the protein as pending
        self.proteinsToLoad = LoadingProtein(atoms: atoms, atomIdentifiers: atomIdentifiers)
        self.importObjects = true

        // Import protein to scene
        if importObjects {
            while self.proteinsToLoad?.state == .loading {

                var newAtomPosition: simd_float3?
                var newAtomId: Int?
                (newAtomPosition, newAtomId) = self.proteinsToLoad?.getNextAtom() ?? (nil, nil)

                guard let newAtomPosition = newAtomPosition else { return }
                guard let newAtomId = newAtomId else { return }

                let atomGeometry = SCNSphere(radius: CGFloat(getAtomicRadius(atomType: newAtomId)))
                atomGeometry.firstMaterial = self.atomMaterial
                let newAtomNode = SCNNode(geometry: atomGeometry)
                newAtomNode.position = SCNVector3(newAtomPosition)
                self.proteinAxis?.addChildNode(newAtomNode)
            }
        }

    }

    // MARK: - Render loop

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Do things at updateAtTime
    }

}
