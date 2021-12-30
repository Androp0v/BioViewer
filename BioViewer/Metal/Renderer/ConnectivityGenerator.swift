//
//  ConnectivityGenerator.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 24/12/21.
//

import Foundation
import Metal

class ConnectivityGenerator {
        
    func computeConnectivity(protein: Protein) -> [LinkStruct] {
        
        var linkedAtoms = [LinkStruct]()
        
        for indexA in 0..<protein.atoms.count {
            for indexB in 0..<indexA {
                let atomA = protein.atoms[indexA]
                let atomB = protein.atoms[indexB]
                // FIXME: LINKS
                if distance(atomA, atomB) < 1.6 {
                    // Atoms close enough, create an impostor cylinder
                    linkedAtoms.append(LinkStruct(atom_A: atomA,
                                                  atom_B: atomB,
                                                  cylinder_center: (atomA + atomB) / 2,
                                                  link_radius: 0.05))
                }
            }
        }
        
        return linkedAtoms
    }
}
