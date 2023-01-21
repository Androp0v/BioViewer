//
//  ProteinResidueComposition.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 20/1/23.
//

import Foundation

class ProteinResidueComposition {
    
    var residueCounts = [Residue: Int]()
    
    var totalCount: Int {
        var sum: Int  = 0
        for residueCount in residueCounts.values {
            sum += residueCount
        }
        return sum
    }
    
    static func +=(lhs: inout ProteinResidueComposition, rhs: ProteinResidueComposition) {
        lhs.residueCounts.merge(rhs.residueCounts, uniquingKeysWith: { lhsCount, rhsCount in
            return lhsCount + rhsCount
        })
    }
    
    init() {}
    
    init(residues: [Residue]) {
        for residue in residues {
            if let currentCount = residueCounts[residue] {
                residueCounts[residue] = currentCount + 1
            } else {
                residueCounts[residue] = 1
            }
        }
    }
}
