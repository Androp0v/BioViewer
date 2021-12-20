//
//  ParsePDB.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/11/21.
//

import Foundation
import simd

// MARK: - PDB Parsing
extension FileParser {
    
    private class ParsedSubunit {
        var id: Int
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
    
    func parsePDBLike(fileName: String, fileExtension: String, byteSize: Int?, rawText: String, proteinViewModel: ProteinViewModel?, originalFileInfo: ProteinFileInfo? = nil) throws -> ProteinFile {

        var atomArray = ContiguousArray<simd_float3>()
        var atomIdentifiers = [UInt8]()
        var totalAtomArrayComposition = AtomArrayComposition()
        // Initialize empty subunit
        var subunits: [ParsedSubunit] = [ParsedSubunit(id: 0)]
        
        var subunitCount: Int = 0
        
        // Protein file data
        let fileInfo = ProteinFileInfo(pdbID: originalFileInfo?.pdbID,
                                       description: originalFileInfo?.description,
                                       authors: originalFileInfo?.authors,
                                       sourceLines: originalFileInfo?.sourceLines)

        var sequenceArray = [String]()
        var sequenceIdentifiers = [Int]()

        var currentResId: Int = -1
        var currentLine: Int = 0
            
        let totalLineCount = rawText.reduce(into: 0) { (count, letter) in
           if letter == "\n" {
              count += 1
           }
        }
        
        var progress: Float {
            return Float(currentLine) / Float(totalLineCount)
        }

        rawText.enumerateLines(invoking: { line, stop in
            
            currentLine += 1
            proteinViewModel?.statusProgress(progress: progress)
            
            // TO-DO: Do this in parallel with the ATOM decoding
            if line.starts(with: "HEADER") {
                guard originalFileInfo?.pdbID == nil else {
                    // We already know the PDB ID, don't overwrite it
                    return
                }
                let startPDBID = line.index(line.startIndex, offsetBy: PDBConstants.pdbIdStart)
                let endPDBID = line.index(line.startIndex, offsetBy: PDBConstants.pdbIdEnd)
                let rangePDBID = startPDBID..<endPDBID

                let pdbIDString = line[rangePDBID].replacingOccurrences(of: " ", with: "")
                
                fileInfo.pdbID = pdbIDString
            }
            
            // Try to retrieve the protein info from the headers
            // TO-DO: Do this in parallel with the ATOM decoding
            if line.starts(with: "TITLE") {
                guard originalFileInfo?.description == nil else {
                    // We already know the protein description, don't overwrite it
                    return
                }
                var rawTitleLine = String(line.dropFirst(PDBConstants.titleKeywordLength))
                
                // Strip trailing newline
                rawTitleLine = String(rawTitleLine.trimmingCharacters(in: .newlines))
                
                // Strip trailing whitespaces
                while (rawTitleLine.last?.isWhitespace) ?? false {
                    rawTitleLine = String(rawTitleLine.dropLast())
                }
                
                // Add to existing description or create a new one if empty
                if fileInfo.description != nil {
                    fileInfo.description! += String(rawTitleLine)
                } else {
                    fileInfo.description = String(rawTitleLine)
                    return
                }
            }
            
            // Retrieve authors
            // TO-DO: Do this in parallel with the ATOM decoding
            if line.starts(with: "AUTHOR") {
                guard originalFileInfo?.authors == nil else {
                    // We already know the PDB authors, don't overwrite them
                    return
                }
                var rawAuthorLine = String(line.dropFirst(PDBConstants.titleKeywordLength))
                
                // Strip trailing newline
                rawAuthorLine = String(rawAuthorLine.trimmingCharacters(in: .newlines))
                
                // Strip trailing whitespaces
                while (rawAuthorLine.last?.isWhitespace) ?? false {
                    rawAuthorLine = String(rawAuthorLine.dropLast())
                }
                
                // Add to existing description or create a new one if empty
                if fileInfo.authors != nil {
                    fileInfo.authors! += String(rawAuthorLine)
                } else {
                    fileInfo.authors = String(rawAuthorLine)
                    return
                }
            }
            
            // Check if this line marks the end of a subunit
            if line.starts(with: "TER") {
                subunitCount += 1
                subunits.append(ParsedSubunit(id: subunitCount))
            }
            
            // We're only interested in the lines that contain atom positions
            if line.starts(with: "ATOM") {

                // Check that the input line has the expected length (or more)
                // to avoid IndexOutOfRange exceptions.
                guard line.count >= PDBConstants.expectedLineLength else {
                    fileInfo.warningIndices.append(currentLine)
                    return
                }

                // Swift strings can't be indexed using Int and have to use Index
                // instead (since under the hood not all string characters are the
                // same length, due to Unicode and stuff).

                // Get residue id (1, 2, 3...) for current atom
                let startResId = line.index(line.startIndex, offsetBy: PDBConstants.resIdStart)
                let endResId = line.index(line.startIndex, offsetBy: PDBConstants.resIdEnd)
                let rangeResId = startResId..<endResId

                if let resId = Int( line[rangeResId].replacingOccurrences(of: " ", with: "") ) {
                    // Avoid adding the residue id more than once
                    if currentResId != resId {
                        currentResId = resId
                        sequenceIdentifiers.append(resId)

                        // Get residue name (ALA, GLN, LYS...) for current atom, now that we know it
                        // belongs to a different residue than the last one.

                        let startResName = line.index(line.startIndex, offsetBy: PDBConstants.resNameStart)
                        let endResName = line.index(line.startIndex, offsetBy: PDBConstants.resNameEnd)
                        let rangeResName = startResName..<endResName

                        let resName = line[rangeResName].replacingOccurrences(of: " ", with: "")
                        sequenceArray.append(resName)
                    }
                } else {
                    proteinViewModel?.statusViewModel.setWarning(warning:
                        NSLocalizedString("Failed to identify residue ID for atom in line", comment: "") + " \(currentLine)."
                    )
                    fileInfo.warningIndices.append(currentLine)
                }

                // Retrieve atom element

                let startElement = line.index(line.startIndex, offsetBy: PDBConstants.elementStart)
                let endElement = line.index(line.startIndex, offsetBy: PDBConstants.elementEnd)
                let rangeElement = startElement..<endElement

                let elementString = line[rangeElement].replacingOccurrences(of: " ", with: "")

                // Normalize atom element, might be of "UNKNOWN" type
                let element = getAtomId(atomName: String(elementString))

                // Get atom coordinates

                let startX = line.index(line.startIndex, offsetBy: PDBConstants.xPositionStart)
                let endX = line.index(line.startIndex, offsetBy: PDBConstants.xPositionEnd)
                let rangeX = startX..<endX

                let startY = line.index(line.startIndex, offsetBy: PDBConstants.yPositionStart)
                let endY = line.index(line.startIndex, offsetBy: PDBConstants.yPositionEnd)
                let rangeY = startY..<endY

                let startZ = line.index(line.startIndex, offsetBy: PDBConstants.zPositionStart)
                let endZ = line.index(line.startIndex, offsetBy: PDBConstants.zPositionEnd)
                let rangeZ = startZ..<endZ

                // Check that all 3 coordinates are non-nil so we don't end up
                // with atoms with partial coordinates. Remove whitespaces too
                // or float-casting will return nil.

                guard let x = Float( line[rangeX].replacingOccurrences(of: " ", with: "") ),
                      let y = Float( line[rangeY].replacingOccurrences(of: " ", with: "") ),
                      let z = Float( line[rangeZ].replacingOccurrences(of: " ", with: "") )
                else {
                    proteinViewModel?.statusViewModel.setWarning(warning:
                        NSLocalizedString("Ignored atom in line", comment: "")
                        + " \(currentLine)"
                        + " due to invalid coordinates."
                    )
                    fileInfo.warningIndices.append(currentLine)
                    return
                }

                // Save atom position to array based on element

                switch element {
                case AtomType.CARBON:
                    subunits.last?.atomArrayComposition.carbonCount += 1
                    subunits.last?.carbonArray.append(simd_float3(x, y, z))
                case AtomType.NITROGEN:
                    subunits.last?.atomArrayComposition.nitrogenCount += 1
                    subunits.last?.nitrogenArray.append(simd_float3(x, y, z))
                case AtomType.HYDROGEN:
                    subunits.last?.atomArrayComposition.hydrogenCount += 1
                    subunits.last?.hydrogenArray.append(simd_float3(x, y, z))
                case AtomType.OXYGEN:
                    subunits.last?.atomArrayComposition.oxygenCount += 1
                    subunits.last?.oxygenArray.append(simd_float3(x, y, z))
                case AtomType.SULFUR:
                    subunits.last?.atomArrayComposition.sulfurCount += 1
                    subunits.last?.sulfurArray.append(simd_float3(x, y, z))
                default:
                    subunits.last?.atomArrayComposition.othersCount += 1
                    subunits.last?.othersArray.append(simd_float3(x, y, z))
                    subunits.last?.othersIDs.append(element)
                }

            }
        })

        // Add element array contents into the contiguous array
        var totalCount: Int = 0
        for subunit in subunits {
            totalCount += subunit.atomArrayComposition.totalCount
        }
        atomArray.reserveCapacity(MemoryLayout<simd_float3>.stride * totalCount)
        
        for subunit in subunits {
            atomArray.append(contentsOf: subunit.carbonArray)
            atomArray.append(contentsOf: subunit.nitrogenArray)
            atomArray.append(contentsOf: subunit.hydrogenArray)
            atomArray.append(contentsOf: subunit.oxygenArray)
            atomArray.append(contentsOf: subunit.sulfurArray)
            atomArray.append(contentsOf: subunit.othersArray)
            
            // Add atom identifiers codes in the right order (so atomArray[i] corresponds
            // has an atomIdentifiers[i] identifier.
            atomIdentifiers.append(contentsOf: Array(repeating: AtomType.CARBON,
                                                     count: subunit.atomArrayComposition.carbonCount))
            atomIdentifiers.append(contentsOf: Array(repeating: AtomType.NITROGEN,
                                                     count: subunit.atomArrayComposition.nitrogenCount))
            atomIdentifiers.append(contentsOf: Array(repeating: AtomType.HYDROGEN,
                                                     count: subunit.atomArrayComposition.hydrogenCount))
            atomIdentifiers.append(contentsOf: Array(repeating: AtomType.OXYGEN,
                                                     count: subunit.atomArrayComposition.oxygenCount))
            atomIdentifiers.append(contentsOf: Array(repeating: AtomType.SULFUR,
                                                     count: subunit.atomArrayComposition.sulfurCount))
            atomIdentifiers.append(contentsOf: subunit.othersIDs)
        }
        
        for subunit in subunits {
            totalAtomArrayComposition += subunit.atomArrayComposition
        }
        
        var subunitIndex = 0
        var proteinSubunits = [ProteinSubunit]()
        for subunit in subunits {
            // The last 'parsed' subunit may be empty, discard it
            guard subunit.atomArrayComposition.totalCount != 0 else {
                continue
            }
            proteinSubunits.append(ProteinSubunit(id: subunit.id,
                                                  atomCount: subunit.atomArrayComposition.totalCount,
                                                  indexStart: subunitIndex))
            subunitIndex += subunit.atomArrayComposition.totalCount
        }
        
        guard atomArray.count > 0 else {
            throw ImportError.emptyAtomCount
        }
        
        if subunitCount == 0 {
            proteinViewModel?.statusViewModel.setWarning(warning:
                NSLocalizedString("No TER keyword found to mark the end of a chain, subunit count may be wrong", comment: "")
            )
        }
        
        fileInfo.sourceLines = rawText.components(separatedBy: .newlines)
        
        // Return ProteinFile
        var protein = Protein(configurationCount: 1,
                              configurationEnergies: nil,
                              subunitCount: subunitCount,
                              subunits: proteinSubunits,
                              atoms: &atomArray,
                              atomArrayComposition: &totalAtomArrayComposition,
                              atomIdentifiers: atomIdentifiers,
                              sequence: sequenceArray)
        
        return ProteinFile(fileType: .staticStructure,
                           fileName: fileName,
                           fileExtension: fileExtension,
                           protein: &protein,
                           fileInfo: fileInfo,
                           byteSize: byteSize)
    }
}
