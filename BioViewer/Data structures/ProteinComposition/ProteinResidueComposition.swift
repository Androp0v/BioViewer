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
