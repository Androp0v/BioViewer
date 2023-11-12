//
//  ProteinSubunit.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 25/11/21.
//

import Foundation

/// Struct holding the contents of a protein subunit.
public struct ProteinSubunit {
        
    /// The subunit index inside its parent protein.
    public let indexInProtein: Int
    
    public enum SubunitKind {
        case chain
        case nonChain
        case unknown
    }
    public let kind: SubunitKind

    // MARK: - Atoms
    
    /// Number of atoms in the subunit.
    public var atomCount: Int
    /// Index for the offset for the subunit atoms in the parent protein atom array.
    public var startIndex: Int
    
    // MARK: - Initialization
    
    public init(indexInProtein: Int, kind: SubunitKind, atomCount: Int, startIndex: Int) {
        self.indexInProtein = indexInProtein
        self.kind = kind
        self.atomCount = atomCount
        self.startIndex = startIndex
    }
    
    // MARK: - Computed
    
    public var subunitName: String {
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
            if indexInProtein < 26 {
                return "Subunit \(letters[indexInProtein])"
            } else {
                return "Subunit \(indexInProtein)"
            }
        case .nonChain:
            return "Non-chain atoms"
        }
    }
}
