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

    // MARK: - Protein loading
    private var proteinsToLoad: LoadingProtein?
    private var atomMaterial: SCNMaterial?
    private var proteinAxis: SCNNode?

    // MARK: - Functions

    /// Add protein to the current scene atom by atom.
    /// - Parameter atoms: Atom positions.
    func addProtein(atoms: [simd_float3], atomIdentifiers: [Int]) {

        // Common atom material for all atoms
        let atomMaterial = SCNMaterial()
        atomMaterial.diffuse.contents = UIColor.green
        atomMaterial.lightingModel = .blinn
        atomMaterial.reflective.contents = UIColor.black
        atomMaterial.reflective.intensity = 1
        self.atomMaterial = atomMaterial

        // Protein axis
        let proteinAxis = SCNNode()
        proteinAxis.position = SCNVector3(0,0,0)
        scene?.rootNode.addChildNode(proteinAxis)
        self.proteinAxis = proteinAxis

        // Mark the protein as pending loading
        self.proteinsToLoad = LoadingProtein(atoms: atoms, atomIdentifiers: atomIdentifiers)

        // Import protein to scene
        while self.proteinsToLoad?.state == .loading {

            // Retrieve next atom from the LoadingProtein structure
            var newAtomPosition: simd_float3?
            var newAtomId: Int?
            (newAtomPosition, newAtomId) = self.proteinsToLoad?.getNextAtom() ?? (nil, nil)

            // Ignore atoms with invalid positions or IDs
            guard let newAtomPosition = newAtomPosition else { return }
            guard let newAtomId = newAtomId else { return }

            // We need to generate the sphere for each atom because they don't
            // allhave the same size
            let atomGeometry = SCNSphere(radius: CGFloat(getAtomicRadius(atomType: newAtomId)))
            // Low segmentCount to improve performance
            atomGeometry.segmentCount = 14
            // Set the atom material to the common atom material
            atomGeometry.firstMaterial = atomMaterial
            // Add the new atom SCNNode to the scene
            let newAtomNode = SCNNode(geometry: atomGeometry)
            newAtomNode.position = SCNVector3(newAtomPosition)
            self.proteinAxis?.addChildNode(newAtomNode)
        }

    }

    // MARK: - Render loop

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Do things at updateAtTime
    }

}
