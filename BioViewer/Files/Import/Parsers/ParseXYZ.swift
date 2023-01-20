//
//  ParseXYZ.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 13/12/21.
//

import Foundation

private enum XYZConstants {
    /// Number of components in an atom coordinates line.
    static let atomLineNumberOfComponents: Int = 4
}

extension FileParser {
    
    private class ParsedConfiguration {
        var id: Int
        var energy: Float?
        // Make one atom array per common element
        var carbonArray = [simd_float3]()
        var nitrogenArray = [simd_float3]()
        var hydrogenArray = [simd_float3]()
        var oxygenArray = [simd_float3]()
        var sulfurArray = [simd_float3]()
        var othersArray = [simd_float3]()
        var atomElements = [AtomElement]()
        var atomArrayComposition = ProteinElementComposition()
        
        init(id: Int) {
            self.id = id
        }
    }
    
    // MARK: - Parse XYZ
    func parseXYZ(fileName: String, fileExtension: String, byteSize: Int?, rawText: String, proteinViewModel: ProteinViewModel?, originalFileInfo: ProteinFileInfo? = nil) throws -> ProteinFile {
        
        var atomArray = ContiguousArray<simd_float3>()
        var energyArray: [Float]?
        var atomElements = [AtomElement]()
        var atomArrayComposition = ProteinElementComposition()
        
        // Initialize empty configuration
        var configurations: [ParsedConfiguration] = [ParsedConfiguration(id: 0)]
        
        func createNewConfigurationUnlessEmpty() {
            guard configurations.last?.atomArrayComposition.totalCount != 0 else {
                // No need to create a new configuration, the last one is already empty
                return
            }
            configurations.append(contentsOf: [ParsedConfiguration(id: configurations.count)])
        }
        
        // Protein file data
        let fileInfo = ProteinFileInfo(pdbID: originalFileInfo?.pdbID,
                                       description: originalFileInfo?.description,
                                       authors: originalFileInfo?.authors,
                                       sourceLines: originalFileInfo?.sourceLines)
        var currentLine: Int = 0
            
        let totalLineCount = rawText.reduce(into: 0) { (count, letter) in
           if letter == "\n" {
              count += 1
           }
        }
        
        var progress: Float {
            return Float(currentLine) / Float(totalLineCount)
        }

        rawText.enumerateLines(invoking: { line, _ in
            
            currentLine += 1
            proteinViewModel?.statusProgress(progress: progress)
            
            let lineElements = line.components(separatedBy: .whitespaces).filter({ !$0.isEmpty })
            guard lineElements.count >= XYZConstants.atomLineNumberOfComponents else {
                createNewConfigurationUnlessEmpty()
                return
            }
            
            // Try to parse energy
            let normalizedLine = line.lowercased().components(separatedBy: .whitespacesAndNewlines).joined(separator: "")
            if normalizedLine.contains("energy=") {
                let components = normalizedLine.components(separatedBy: "energy=")
                if components.count >= 2 {
                    configurations.last?.energy = Float(components[1])
                }
            }
            
            // Retrieve atom element

            let elementString = lineElements[0].replacingOccurrences(of: " ", with: "")

            // Normalize atom element, might be of "UNKNOWN" type
            let element = AtomElement(string: elementString)

            // Get atom coordinates

            // Check that all 3 coordinates are non-nil so we don't end up
            // with atoms with partial coordinates. Remove whitespaces too
            // or float-casting will return nil.

            guard let x = Float( lineElements[1] ),
                  let y = Float( lineElements[2] ),
                  var z = Float( lineElements[3] )
            else {
                createNewConfigurationUnlessEmpty()
                return
            }
            
            // Since the projection matrix is left-handed, fix the chirality of the molecules
            z = -z
            
            // Save atom position to array based on element
            switch element {
            case .carbon:
                configurations.last?.carbonArray.append(simd_float3(x, y, z))
            case .nitrogen:
                configurations.last?.nitrogenArray.append(simd_float3(x, y, z))
            case .hydrogen:
                configurations.last?.hydrogenArray.append(simd_float3(x, y, z))
            case .oxygen:
                configurations.last?.oxygenArray.append(simd_float3(x, y, z))
            case .sulfur:
                configurations.last?.sulfurArray.append(simd_float3(x, y, z))
            default:
                configurations.last?.othersArray.append(simd_float3(x, y, z))
            }
            configurations.last?.atomElements.append(element)
        })
                
        guard let firstConfiguration = configurations.first else {
            throw ImportError.unknownError
        }
        
        let configurationCount: Int = configurations.count
        
        // Add element array contents into the contiguous array
        let totalCount: Int = firstConfiguration.atomArrayComposition.totalCount
        atomArray.reserveCapacity(MemoryLayout<simd_float3>.stride * totalCount * configurationCount)
        
        for configuration in configurations {
            atomArray.append(contentsOf: configuration.carbonArray)
            atomArray.append(contentsOf: configuration.nitrogenArray)
            atomArray.append(contentsOf: configuration.hydrogenArray)
            atomArray.append(contentsOf: configuration.oxygenArray)
            atomArray.append(contentsOf: configuration.sulfurArray)
            atomArray.append(contentsOf: configuration.othersArray)
            
            if let configurationEnergy = configuration.energy {
                if energyArray == nil {
                    energyArray = [Float]()
                }
                energyArray?.append(configurationEnergy)
            }
        }
        
        guard atomArray.count > 0 else {
            throw ImportError.emptyAtomCount
        }

        atomElements.append(contentsOf: firstConfiguration.atomElements)
        atomArrayComposition = ProteinElementComposition(elements: atomElements)
        
        let proteinSubunits = [ProteinSubunit(id: firstConfiguration.id,
                                              kind: .unknown,
                                              atomCount: firstConfiguration.atomArrayComposition.totalCount,
                                              startIndex: 0)]
        
        fileInfo.sourceLines = rawText.components(separatedBy: .newlines)
        
        // Return ProteinFile
        let protein = Protein(configurationCount: configurationCount,
                              configurationEnergies: energyArray,
                              subunitCount: 1,
                              subunits: proteinSubunits,
                              atoms: atomArray,
                              elementComposition: atomArrayComposition,
                              atomElements: atomElements,
                              residueComposition: nil,
                              atomResidues: nil,
                              sequence: nil)
        
        let fileType: ProteinFileType = configurations.count > 1 ? .dynamicStructure : .staticStructure
        
        return ProteinFile(fileType: fileType,
                           fileName: fileName,
                           fileExtension: fileExtension,
                           models: [protein],
                           fileInfo: fileInfo,
                           byteSize: byteSize)
    }
    
}
