//
//  ConnectivityGenerator.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 24/12/21.
//

import BioViewerFoundation
import Foundation
import Metal

struct ProteinConnectivity {
    let computedBonds: [BondStruct]
    let computedBondCounts: [Int]
    let computedBondConfigurationStarts: [Int]
}

class ConnectivityGenerator {
        
    func computeConnectivity(protein: Protein, dataSource: ProteinDataSource, statusViewModel: StatusViewModel?, statusAction: StatusAction) async {
        
        var computedBonds = [BondStruct]()
        var computedBondCounts = [Int]()
        var computedBondConfigurationStarts = [Int]()
        
        var computedInteractions = 0
        var progress: Double {
            return Double(computedInteractions) / Double( pow(Float(protein.atomCount * protein.configurationCount), 2) / 2 )
        }
                
        for configurationIndex in 0..<protein.configurationCount {
            // Index where the configuration starts in the atom array
            let configurationStartIndex = configurationIndex * protein.atomCount
            // Index where the configuration ends in the atom array
            let configurationEndIndex = configurationIndex * protein.atomCount + protein.atomCount
            
            // Number of bonds in this configuration
            var bondCountInCurrentConfiguration = 0
            
            // Loop over all the atoms in the configuration (to avoid bonding atoms in different configurations)
            for indexA in configurationStartIndex..<configurationEndIndex {
                
                // Check whether this computation has been cancelled before computing a new
                // connectivity row. Results will be discarded.
                if Task.isCancelled { return }
                
                // Update progress
                await statusViewModel?.updateProgress(statusAction, progress: progress)
                
                // Compute a new matrix row
                for indexB in configurationStartIndex..<indexA {
                    let atomA = protein.atoms[indexA]
                    let atomB = protein.atoms[indexB]
                    // FIXME: This should use the atom's covalent radius
                    if distance(atomA, atomB) < 1.6 {
                        // Atoms close enough, create an impostor cylinder
                        computedBonds.append(
                            BondStruct(
                                atomA: atomA,
                                atomB: atomB,
                                cylinderCenter: (atomA + atomB) / 2,
                                bondRadius: 0.05
                            )
                        )
                        bondCountInCurrentConfiguration += 1
                    }
                }
                computedInteractions += indexA
            }
            
            // Update configuration data
            computedBondCounts.append(bondCountInCurrentConfiguration)
            computedBondConfigurationStarts.append( (computedBondConfigurationStarts.last ?? 0) + bondCountInCurrentConfiguration )
        }
        
        computedBondConfigurationStarts.insert(0, at: 0)
        computedBondConfigurationStarts.remove(at: computedBondConfigurationStarts.count - 1)
        
        try? await dataSource.updateProteinConnectivity(
            ProteinConnectivity(
                computedBonds: computedBonds,
                computedBondCounts: computedBondCounts,
                computedBondConfigurationStarts: computedBondConfigurationStarts
            ),
            for: protein
        )
    }
}
