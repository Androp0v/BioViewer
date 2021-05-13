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
                self.proteinCount = self.proteins.count
            }
            // Sum all atom counts from all proteins in the datasource
            var newTotalAtomCount = 0
            for protein in self.proteins {
                newTotalAtomCount += protein.atomCount
            }
            // Publishers need to be updated in the main queue
            DispatchQueue.main.async {
                self.totalAtomCount = newTotalAtomCount
            }
        }
    }

    public var proteinViewModel: ProteinViewModel?

    @Published var proteinCount: Int = 0
    @Published var totalAtomCount: Int = 0

    // MARK: - Public functions

    /// Add protein to a ```ProteinView``` datasource.
    public func addProteinToDataSource(atoms: [simd_float3], atomIdentifiers: [Int], addToScene: Bool = false) {
        var newProtein = Protein(atoms: atoms, atomIdentifiers: atomIdentifiers)
        proteins.append(newProtein)
        if addToScene {
            self.proteinViewModel?.sceneDelegate.addProteinToScene(protein: &newProtein)
        }
    }

    /// Get the number of active proteins in a given ```ProteinView```.
    /// - Returns: Number of active proteins that are available in a given
    /// ```ProteinView```, even if they are not currently being displayed.
    public func getNumberOfProteins() -> Int {
        return proteins.count
    }

}
