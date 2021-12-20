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
        var othersIDs = [UInt8]()
        var atomArrayComposition = AtomArrayComposition()
        
        init(id: Int) {
            self.id = id
        }
    }
    
    // MARK: - Parse XYZ
    func parseXYZ(fileName: String, fileExtension: String, byteSize: Int?, rawText: String, proteinViewModel: ProteinViewModel?, originalFileInfo: ProteinFileInfo? = nil) throws -> ProteinFile {
        
        var atomArray = ContiguousArray<simd_float3>()
        var atomIdentifiers = [UInt8]()
        var atomArrayComposition = AtomArrayComposition()
        
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

            // Retrieve atom element

            let elementString = lineElements[0].replacingOccurrences(of: " ", with: "")

            // Normalize atom element, might be of "UNKNOWN" type
            let element = getAtomId(atomName: String(elementString))

            // Get atom coordinates

            // Check that all 3 coordinates are non-nil so we don't end up
            // with atoms with partial coordinates. Remove whitespaces too
            // or float-casting will return nil.

            guard let x = Float( lineElements[1] ),
                  let y = Float( lineElements[2] ),
                  let z = Float( lineElements[3] )
            else {
                createNewConfigurationUnlessEmpty()
                return
            }

            // Save atom position to array based on element

            switch element {
            case AtomType.CARBON:
                configurations.last?.atomArrayComposition.carbonCount += 1
                configurations.last?.carbonArray.append(simd_float3(x, y, z))
            case AtomType.NITROGEN:
                configurations.last?.atomArrayComposition.nitrogenCount += 1
                configurations.last?.nitrogenArray.append(simd_float3(x, y, z))
            case AtomType.HYDROGEN:
                configurations.last?.atomArrayComposition.hydrogenCount += 1
                configurations.last?.hydrogenArray.append(simd_float3(x, y, z))
            case AtomType.OXYGEN:
                configurations.last?.atomArrayComposition.oxygenCount += 1
                configurations.last?.oxygenArray.append(simd_float3(x, y, z))
            case AtomType.SULFUR:
                configurations.last?.atomArrayComposition.sulfurCount += 1
                configurations.last?.sulfurArray.append(simd_float3(x, y, z))
            default:
                configurations.last?.atomArrayComposition.othersCount += 1
                configurations.last?.othersArray.append(simd_float3(x, y, z))
                configurations.last?.othersIDs.append(element)
            }
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
        }
        
        guard atomArray.count > 0 else {
            throw ImportError.emptyAtomCount
        }
        
        // Add atom identifiers codes in the right order (so atomArray[i] corresponds
        // has an atomIdentifiers[i] identifier.
        atomIdentifiers.append(contentsOf: Array(repeating: AtomType.CARBON,
                                                 count: firstConfiguration.atomArrayComposition.carbonCount))
        atomIdentifiers.append(contentsOf: Array(repeating: AtomType.NITROGEN,
                                                 count: firstConfiguration.atomArrayComposition.nitrogenCount))
        atomIdentifiers.append(contentsOf: Array(repeating: AtomType.HYDROGEN,
                                                 count: firstConfiguration.atomArrayComposition.hydrogenCount))
        atomIdentifiers.append(contentsOf: Array(repeating: AtomType.OXYGEN,
                                                 count: firstConfiguration.atomArrayComposition.oxygenCount))
        atomIdentifiers.append(contentsOf: Array(repeating: AtomType.SULFUR,
                                                 count: firstConfiguration.atomArrayComposition.sulfurCount))
        atomIdentifiers.append(contentsOf: firstConfiguration.othersIDs)
        
        atomArrayComposition = firstConfiguration.atomArrayComposition
        
        let proteinSubunits = [ProteinSubunit(id: firstConfiguration.id,
                                              atomCount: firstConfiguration.atomArrayComposition.totalCount,
                                              indexStart: 0)]
        
        fileInfo.sourceLines = rawText.components(separatedBy: .newlines)
        
        // Return ProteinFile
        var protein = Protein(configurationCount: configurationCount,
                              subunitCount: 1,
                              subunits: proteinSubunits,
                              atoms: &atomArray,
                              atomArrayComposition: &atomArrayComposition,
                              atomIdentifiers: atomIdentifiers,
                              sequence: nil)
        
        let fileType: ProteinFileType = configurations.count > 1 ? .dynamicStructure : .staticStructure
        
        return ProteinFile(fileType: fileType,
                           fileName: fileName,
                           fileExtension: fileExtension,
                           protein: &protein,
                           fileInfo: fileInfo,
                           byteSize: byteSize)
    }
    
}
