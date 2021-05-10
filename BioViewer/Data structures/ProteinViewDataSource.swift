//
//  ProteinViewDataSource.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/5/21.
//

import Foundation

/// Handle all source data for a ```ProteinView``` that is not related to the
/// scene nor the appearance, like the ```Protein``` objects that have been
/// imported or computed values.
class ProteinViewDataSource: ObservableObject {

    private var proteins: [Protein] = [Protein]()

    // MARK: - Public functions

    /// Add protein to a ```ProteinView``` datasource.
    /// - Parameter protein: ```Protein``` object.
    public func addProtein(protein: Protein) {
        proteins.append(protein)
    }

    /// Get the number of active proteins in a given ```ProteinView```.
    /// - Returns: Number of active proteins that are available in a given
    /// ```ProteinView```, even if they are not currently being displayed.
    public func getNumberOfProteins() -> Int {
        return proteins.count
    }

}
