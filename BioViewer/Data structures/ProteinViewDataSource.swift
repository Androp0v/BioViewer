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
    private(set) var proteins: [Protein] = [Protein]() {
        // Run when a new protein is added to the datasource
        didSet {
            // Publishers need to be updated in the main queue
            DispatchQueue.main.async {
                self.proteinViewModel?.proteinCount = self.proteins.count
            }
            // Sum all subunit counts from all proteins in the datasource
            var newSubunitCount = 0
            for protein in self.proteins {
                newSubunitCount += protein.subunitCount
            }
            // Sum all atom counts from all proteins in the datasource
            var newTotalAtomCount = 0
            for protein in self.proteins {
                newTotalAtomCount += protein.atomCount
            }
            // Publishers need to be updated in the main queue
            DispatchQueue.main.async {
                self.proteinViewModel?.totalSubunitCount = newSubunitCount
                self.proteinViewModel?.totalAtomCount = newTotalAtomCount
            }
        }
    }

    public var proteinViewModel: ProteinViewModel?

    // MARK: - Public functions

    /// Add protein to a ```ProteinView``` datasource.
    public func addProteinToDataSource(protein: inout Protein, addToScene: Bool = false) {
        proteins.append(protein)
        if addToScene {
            
            // TO-DO: Opaque geometries
            /*
            // Generate a sphere mesh for each atom in the protein
            let (vertexData, atomTypeData, indexData) = MetalScheduler.shared.createSphereModel(protein: protein)
            guard var vertexData = vertexData else { return }
            guard var atomTypeData = atomTypeData else { return }
            guard var indexData = indexData else { return }
            // Pass the new mesh to the renderer
            proteinViewModel?.renderer.addOpaqueBuffers(vertexBuffer: &vertexData,
                                                        atomTypeBuffer: &atomTypeData,
                                                        indexBuffer: &indexData)
            */
            
            // Generate a billboard quad for each atom in the protein
            let (vertexData, subunitData, atomTypeData, indexData) = MetalScheduler.shared.createImpostorSpheres(protein: protein)
            guard var vertexData = vertexData else { return }
            guard var subunitData = subunitData else { return }
            guard var atomTypeData = atomTypeData else { return }
            guard var indexData = indexData else { return }
            // Pass the new mesh to the renderer
            proteinViewModel?.renderer.addBillboardingBuffers(vertexBuffer: &vertexData,
                                                              subunitBuffer: &subunitData,
                                                              atomTypeBuffer: &atomTypeData,
                                                              indexBuffer: &indexData)
            
            // File import finished
            proteinViewModel?.statusFinished(action: StatusAction.importFile)
        }
    }

    /// Get the number of active proteins in a given ```ProteinView```.
    /// - Returns: Number of active proteins that are available in a given
    /// ```ProteinView```, even if they are not currently being displayed.
    public func getNumberOfProteins() -> Int {
        return proteins.count
    }
    
    /// Removes all proteins from the data source and the scene.
    public func removeAllProteinsFromDatasource() {
        proteins = []
        proteinViewModel?.renderer.removeBuffers()
    }

}
