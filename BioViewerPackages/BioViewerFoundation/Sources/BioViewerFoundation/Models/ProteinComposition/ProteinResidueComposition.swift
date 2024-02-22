//
//  ProteinResidueComposition.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 20/1/23.
//

import Foundation

public struct ProteinResidueComposition: Sendable {
    
    /// Dictionary containing the number of atoms of each type of residue.
    public var residueCounts = [Residue: Int]()
    /// The total count of atoms of all types.
    public var totalCount: Int = 0
    
    public static func += (lhs: inout ProteinResidueComposition, rhs: ProteinResidueComposition) {
        lhs.residueCounts.merge(rhs.residueCounts, uniquingKeysWith: { lhsCount, rhsCount in
            return lhsCount + rhsCount
        })
        lhs.totalCount += rhs.totalCount
    }
    
    // MARK: - Init
    
    public init() {}
    
    public init?(residues: [Residue]?) {
        guard let residues else { return nil }
        self.init(residues: residues)
    }
    
    public init(residues: [Residue]) {
        for residue in residues {
            if let currentCount = residueCounts[residue] {
                residueCounts[residue] = currentCount + 1
            } else {
                residueCounts[residue] = 1
            }
        }
        for residueCount in residueCounts.values {
            totalCount += residueCount
        }
    }
}
