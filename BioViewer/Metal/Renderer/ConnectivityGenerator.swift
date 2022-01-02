//
//  ConnectivityGenerator.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 24/12/21.
//

import Foundation
import Metal

class ConnectivityGenerator {
        
    func computeConnectivity(protein: Protein, proteinViewModel: ProteinViewModel?) async {
        
        var computedLinks = [LinkStruct]()
        var computedInteractions = 0
        var progress: Float {
            return Float(computedInteractions) / Float( pow(Float(protein.atomCount), 2) / 2 )
        }
        
        for indexA in 0..<protein.atoms.count {
            
            // Check whether this computation has been cancelled before computing a new
            // connectivity row. Results will be discarded.
            if Task.isCancelled { return }
            
            // Update progress
            proteinViewModel?.statusProgress(progress: progress)
            
            // Compute a new matrix row
            for indexB in 0..<indexA {
                let atomA = protein.atoms[indexA]
                let atomB = protein.atoms[indexB]
                // FIXME: LINKS
                if distance(atomA, atomB) < 1.6 {
                    // Atoms close enough, create an impostor cylinder
                    computedLinks.append(LinkStruct(atom_A: atomA,
                                                  atom_B: atomB,
                                                  cylinder_center: (atomA + atomB) / 2,
                                                  link_radius: 0.05))
                }
            }
            computedInteractions += indexA
        }
        
        protein.links = computedLinks
    }
}
