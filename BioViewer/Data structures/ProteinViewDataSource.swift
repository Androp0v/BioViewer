//
//  ProteinViewDataSource.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/5/21.
//

import Foundation

class ProteinViewDataSource: ObservableObject {

    private var proteins: [Protein] = [Protein]()

    // MARK: - Public functions

    public func addProtein(protein: Protein) {
        proteins.append(protein)
    }

    public func getNumberOfProteins() -> Int {
        return proteins.count
    }

}
