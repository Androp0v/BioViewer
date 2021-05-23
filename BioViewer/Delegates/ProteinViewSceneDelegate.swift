//
//  ProteinViewRendererDelegate.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 7/5/21.
//

import Foundation
import SceneKit
import SwiftUI

class ProteinViewSceneDelegate: NSObject, ObservableObject, SCNSceneRendererDelegate {

    // MARK: - Properties

    public var scene: SCNScene?
    public var proteinViewModel: ProteinViewModel?

    @Published var sceneBackground: Color = Color.black

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
    private var proteinsToLoad: Protein?
    private var atomMaterialProvider: AtomMaterialProvider?
    private var proteinAxis: SCNNode?

    // MARK: - Functions

    /// Add protein to the current scene atom by atom.
    /// - Parameter protein: ```Protein``` object. Marked as ```inout```
    /// so it doesn't get copied-on-write when ```getNextAtom()``` is called (which
    /// will eventually set the ```Protein.state``` to ```true```).
    func addProteinToScene(protein: inout Protein) {

        guard let proteinViewModel = proteinViewModel else { return }

        self.atomMaterialProvider = AtomMaterialProvider()

        // Protein axis
        let proteinAxis = SCNNode()
        proteinAxis.position = SCNVector3(0,0,0)
        self.proteinAxis = proteinAxis

        // Import protein to scene
        while protein.state == .loading {

            // Retrieve next atom from the LoadingProtein structure
            let (newAtomPosition, newAtomId, progress) = protein.getNextAtom()

            // Ignore atoms with invalid positions or IDs
            guard let newAtomPosition = newAtomPosition else { return }
            guard let newAtomId = newAtomId else { return }

            // We need to generate the sphere for each atom because they don't
            // all have the same size
            let atomGeometry = SCNSphere(radius: CGFloat(getAtomicRadius(atomType: newAtomId)))

            // TO-DO: Make this dependant on RAM size
            if protein.atomCount > 20000 {
                // Low segmentCount to improve performance, avoid IOAF Error 11
                // because too many geometries in scene.
                atomGeometry.segmentCount = 8
            } else {
                atomGeometry.segmentCount = 14
            }
            
            // Set the atom material to the common atom material
            switch newAtomId {
            case AtomType.CARBON:
                atomGeometry.firstMaterial = atomMaterialProvider?.carbonMaterial
            case AtomType.NITROGEN:
                atomGeometry.firstMaterial = atomMaterialProvider?.nitrogenMaterial
            case AtomType.OXYGEN:
                atomGeometry.firstMaterial = atomMaterialProvider?.oxygenMaterial
            case AtomType.SULFUR:
                atomGeometry.firstMaterial = atomMaterialProvider?.sulfurMaterial
            default:
                atomGeometry.firstMaterial = atomMaterialProvider?.defaultMaterial
            }
            // Add the new atom SCNNode to the scene
            let newAtomNode = SCNNode(geometry: atomGeometry)
            newAtomNode.position = SCNVector3(newAtomPosition)
            self.proteinAxis?.addChildNode(newAtomNode)

            guard let progress = progress else { return }

            // Update the UI only if significant changes to the progress have been
            // made, here we require changes greater than 1%.
            if progress - (proteinViewModel.progress ?? 0.0) > 0.01 || proteinViewModel.progress == nil {
                proteinViewModel.statusProgress(progress: progress)
            }

        }

        // Make a flattened clone to reduce the number of draw calls at rendering
        // time and improme fps.
        scene?.rootNode.addChildNode(proteinAxis.flattenedClone())

        // File import finished
        proteinViewModel.statusFinished()

    }

    /// Add cloud of points to current scene from a ```UnsafeMutablePointer``` array
    /// of ```simd_float3```.
    func addPointCloud(points: UnsafeMutablePointer<simd_float3>, pointCount: Int) {
        var vertices = [SCNVector3]()
        var indexList = [CInt]()
        for i in 0..<pointCount {
            vertices.append( SCNVector3(points[i]) )
            indexList.append(CInt(indexList.count))
        }

        let vertexSource = SCNGeometrySource(vertices: vertices)

        let indexData  = Data(bytes: indexList, count: MemoryLayout<CInt>.size * indexList.count)
        let indexElement = SCNGeometryElement(
            data: indexData,
            primitiveType: SCNGeometryPrimitiveType.point,
            primitiveCount: pointCount,
            bytesPerIndex: MemoryLayout<CInt>.size
        )

        indexElement.pointSize = 5
        indexElement.minimumPointScreenSpaceRadius = 5
        indexElement.maximumPointScreenSpaceRadius = 5

        let cloud = SCNGeometry(sources: [vertexSource], elements: [indexElement])
        cloud.firstMaterial?.isLitPerPixel = true

        let newNode = SCNNode(geometry: cloud)
        scene?.rootNode.addChildNode(newNode)

    }

    // MARK: - Render loop

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Do things at updateAtTime
    }

}
