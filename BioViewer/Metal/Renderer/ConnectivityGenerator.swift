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
            return Float(computedInteractions) / Float( pow(Float(protein.atomCount * protein.configurationCount), 2) / 2 )
        }
        
        for configurationIndex in 0..<protein.configurationCount {
            // Index where the configuration starts in the atom array
            let configurationStartIndex = configurationIndex * protein.atomCount
            // Index where the configuration ends in the atom array
            let configurationEndIndex = configurationIndex * protein.atomCount + protein.atomCount
            
            // Loop over all the atoms in the configuration
            for indexA in configurationStartIndex..<configurationEndIndex {
                
                // Check whether this computation has been cancelled before computing a new
                // connectivity row. Results will be discarded.
                if Task.isCancelled { return }
                
                // Update progress
                proteinViewModel?.statusProgress(progress: progress)
                
                // Compute a new matrix row
                for indexB in configurationStartIndex..<indexA {
                    let atomA = protein.atoms[indexA]
                    let atomB = protein.atoms[indexB]
                    // FIXME: This should use the atom's covalent radius
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
        }
        
        protein.links = computedLinks
    }
}
