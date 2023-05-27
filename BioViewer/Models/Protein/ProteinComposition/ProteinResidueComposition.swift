//
//  ProteinResidueComposition.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 20/1/23.
//

import Foundation

struct ProteinResidueComposition {
    
    /// Dictionary containing the number of atoms of each type of residue.
    var residueCounts = [Residue: Int]()
    /// The total count of atoms of all types.
    var totalCount: Int = 0
    
    static func += (lhs: inout ProteinResidueComposition, rhs: ProteinResidueComposition) {
        lhs.residueCounts.merge(rhs.residueCounts, uniquingKeysWith: { lhsCount, rhsCount in
            return lhsCount + rhsCount
        })
        lhs.totalCount += rhs.totalCount
    }
    
    // MARK: - Init
    
    init() {}
    
    init(residues: [Residue]) {
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
