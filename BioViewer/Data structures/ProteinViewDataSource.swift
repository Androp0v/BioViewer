//
//  ProteinViewDataSource.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/5/21.
//

import Foundation
import simd

/// Handle all source data for a ```ProteinView``` that is not related to the
/// scene nor the appearance, like the ```Protein``` objects that have been
/// imported or computed values.
class ProteinViewDataSource: ObservableObject {
    
    // MARK: - Properties
    private(set) var files: [ProteinFile] = [ProteinFile]() {
        // Run when a new file is added to the datasource
        didSet {
            // Publishers need to be updated in the main queue
            DispatchQueue.main.async {
                // FIXME: This is number of files, not proteins
                self.proteinViewModel?.proteinCount = self.files.count
            }
            // Sum all subunit counts from all proteins in the datasource
            var newSubunitCount = 0
            for file in self.files {
                newSubunitCount += file.protein.subunitCount
            }
            // Sum all atom counts from all proteins in the datasource
            var newTotalAtomCount = 0
            for file in self.files {
                newTotalAtomCount += file.protein.atomCount
            }
            // Publishers need to be updated in the main queue
            DispatchQueue.main.async {
                self.proteinViewModel?.totalSubunitCount = newSubunitCount
                self.proteinViewModel?.totalAtomCount = newTotalAtomCount
            }
        }
    }

    public weak var proteinViewModel: ProteinViewModel?

    // MARK: - Public functions
    public func addProteinFileToDataSource(proteinFile: ProteinFile, addToScene: Bool) {
        if addToScene {
            // Generate a billboard quad for each atom in the protein
            let (vertexData, subunitData, atomTypeData, indexData) = MetalScheduler.shared.createImpostorSpheres(protein: proteinFile.protein)
            guard var vertexData = vertexData else { return }
            guard var subunitData = subunitData else { return }
            guard var atomTypeData = atomTypeData else { return }
            guard var indexData = indexData else { return }
            // Pass the new mesh to the renderer
            proteinViewModel?.renderer.addBillboardingBuffers(vertexBuffer: &vertexData,
                                                              subunitBuffer: &subunitData,
                                                              atomTypeBuffer: &atomTypeData,
                                                              indexBuffer: &indexData)
            // Fit file in frustum
            if let scene = proteinViewModel?.renderer.scene {
                let cameraDistanceToFit = scene.camera.distanceToFitInFrustum(sphereRadius: proteinFile.protein.boundingSphere.radius,
                                                                              aspectRatio: scene.aspectRatio)
                scene.cameraPosition = simd_float3(0, 0, cameraDistanceToFit)
            }
        }
        // File import finished
        proteinViewModel?.statusFinished(action: StatusAction.importFile)
        files.append(proteinFile)
    }
    
    /// Removes all proteins from the data source and the scene.
    public func removeAllFilesFromDatasource() {
        files = []
        proteinViewModel?.renderer.removeBuffers()
    }

}
