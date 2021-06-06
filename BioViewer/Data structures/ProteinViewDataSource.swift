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

    private(set) var proteins: [Protein] = [Protein]() {
        // Run when a new protein is added to the datasource
        didSet {
            // Publishers need to be updated in the main queue
            DispatchQueue.main.async {
                self.proteinViewModel?.proteinCount = self.proteins.count
            }
            // Sum all atom counts from all proteins in the datasource
            var newTotalAtomCount = 0
            for protein in self.proteins {
                newTotalAtomCount += protein.atomCount
            }
            // Publishers need to be updated in the main queue
            DispatchQueue.main.async {
                self.proteinViewModel?.totalAtomCount = newTotalAtomCount
            }
        }
    }

    public var proteinViewModel: ProteinViewModel?

    // MARK: - Public functions

    /// Add protein to a ```ProteinView``` datasource.
    public func addProteinToDataSource(protein: inout Protein, addToScene: Bool = false) {
        proteins.append(protein)
        if addToScene && AppState.shared.useMetal {
            let (vertexData, atomTypeData, indexData) = MetalScheduler.shared.createSphereModel(protein: protein)
            guard var vertexData = vertexData else { return }
            guard var atomTypeData = atomTypeData else { return }
            guard var indexData = indexData else { return }
            proteinViewModel?.metalRenderer.addBuffers(vertexBuffer: &vertexData,
                                                       atomTypeBuffer: &atomTypeData,
                                                       indexBuffer: &indexData)
            // File import finished
            proteinViewModel?.statusFinished()
        } else {
            self.proteinViewModel?.sceneDelegate.addProteinToScene(protein: &protein)
        }
    }

    /// Get the number of active proteins in a given ```ProteinView```.
    /// - Returns: Number of active proteins that are available in a given
    /// ```ProteinView```, even if they are not currently being displayed.
    public func getNumberOfProteins() -> Int {
        return proteins.count
    }

    public func removeAllProteinsFromDatasource() {
        proteins = []
    }

}
