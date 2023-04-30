//
//  ProteinSubunit.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 25/11/21.
//

import Foundation

/// Struct holding the contents of a protein subunit.
struct ProteinSubunit: Sendable {
    
    let id: Int
    
    enum SubunitKind {
        case chain
        case nonChain
        case unknown
    }
    let kind: SubunitKind

    // MARK: - Atoms
    
    /// Number of atoms in the subunit.
    public var atomCount: Int
    
    /// Index for the offset for the subunit atoms in the parent protein atom array.
    public var startIndex: Int
    
    // MARK: - Initialization
    
    init(id: Int, kind: SubunitKind, atomCount: Int, startIndex: Int) {
        self.id = id
        self.kind = kind
        self.atomCount = atomCount
        self.startIndex = startIndex
    }
    
    // MARK: - Computed
    
    var subunitName: String {
        let letters = ["A",
                       "B",
                       "C",
                       "D",
                       "E",
                       "F",
                       "G",
                       "H",
                       "I",
                       "J",
                       "K",
                       "L",
                       "M",
                       "N",
                       "O",
                       "P",
                       "Q",
                       "R",
                       "S",
                       "T",
                       "U",
                       "V",
                       "W",
                       "X",
                       "Y",
                       "Z"]
        switch self.kind {
        case .chain, .unknown:
            if id < 26 {
                return "Subunit \(letters[id])"
            } else {
                return "Subunit \(id)"
            }
        case .nonChain:
            return "Non-chain atoms"
        }
    }
}
