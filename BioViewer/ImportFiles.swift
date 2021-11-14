//
//  ImportFiles.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 12/5/21.
//

import Foundation
import simd

enum PDBConstants {
    // Expected line length of a properly formatted PDB file
    // (hard to think of such a mythical creature).
    static let expectedLineLength: Int = 78
    
    // Spacing after the TITLE keyword in header until the start
    // of the data.
    static let titleKeywordLength: Int = 10

    // Start and end of the residue name
    static let resNameStart: Int = 17
    static let resNameEnd: Int = 20

    // Start and end of the residue identifier
    static let resIdStart: Int = 22
    static let resIdEnd: Int = 26

    // Start and end of the x coordinate positions
    static let xPositionStart: Int = 30
    static let xPositionEnd: Int = 38

    // Start and end of the y coordinate positions
    static let yPositionStart: Int = 38
    static let yPositionEnd: Int = 46

    // Start and end of the z coordinate positions
    static let zPositionStart: Int = 46
    static let zPositionEnd: Int = 54

    // Start and end of the element name
    static let elementStart: Int = 76
    static let elementEnd: Int = 78
}

enum PDBParsingError: Error {
    case emptyAtomCount
}

func parsePDB(rawText: String, proteinViewModel: ProteinViewModel?) throws -> Protein {

    var atomArray = ContiguousArray<simd_float3>()
    var atomIdentifiers = [UInt8]()
    
    // Protein file data
    var pdbID: String?
    var description: String?

    // Make one atom array per common element
    var carbonArray = [simd_float3]()
    var nitrogenArray = [simd_float3]()
    var hydrogenArray = [simd_float3]()
    var oxygenArray = [simd_float3]()
    var sulfurArray = [simd_float3]()
    var othersArray = [simd_float3]()
    var othersIDs = [UInt8]()

    var atomArrayComposition = AtomArrayComposition()

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
    
    func updateProgress() {
        
    }

    rawText.enumerateLines(invoking: { line, stop in
        
        currentLine += 1
        proteinViewModel?.statusProgress(progress: progress)
        
        // Try to retrieve the protein info from the headers
        // TO-DO: Do this in parallel with the ATOM decoding
        if line.starts(with: "TITLE") {
            var rawTitleLine = String(line.dropFirst(10))
            
            // Strip trailing newline
            rawTitleLine = String(rawTitleLine.trimmingCharacters(in: .newlines))
            
            // Strip trailing whitespaces
            while (rawTitleLine.last?.isWhitespace) ?? false {
                rawTitleLine = String(rawTitleLine.dropLast())
            }
            
            // Add to existing description or create a new one if empty
            if description != nil {
                description! += String(rawTitleLine)
            } else {
                description = String(rawTitleLine)
                return
            }
        }
        
        // We're only interested in the lines that contain atom positions
        if line.starts(with: "ATOM") {

            // Check that the input line has the expected length (or more)
            // to avoid IndexOutOfRange exceptions.
            guard line.count >= PDBConstants.expectedLineLength else {
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
                return
            }

            // Save atom position to array based on element

            switch element {
            case AtomType.CARBON:
                atomArrayComposition.carbonCount += 1
                carbonArray.append(simd_float3(x, y, z))
            case AtomType.NITROGEN:
                atomArrayComposition.nitrogenCount += 1
                nitrogenArray.append(simd_float3(x, y, z))
            case AtomType.HYDROGEN:
                atomArrayComposition.hydrogenCount += 1
                hydrogenArray.append(simd_float3(x, y, z))
            case AtomType.OXYGEN:
                atomArrayComposition.oxygenCount += 1
                oxygenArray.append(simd_float3(x, y, z))
            case AtomType.SULFUR:
                atomArrayComposition.sulfurCount += 1
                sulfurArray.append(simd_float3(x, y, z))
            default:
                atomArrayComposition.othersCount += 1
                othersArray.append(simd_float3(x, y, z))
                othersIDs.append(element)
            }

        }
    })

    // Add element array contents into the contiguous array
    let totalCount = atomArrayComposition.totalCount
    atomArray.reserveCapacity(MemoryLayout<simd_float3>.stride * totalCount)

    atomArray.append(contentsOf: carbonArray)
    atomArray.append(contentsOf: nitrogenArray)
    atomArray.append(contentsOf: hydrogenArray)
    atomArray.append(contentsOf: oxygenArray)
    atomArray.append(contentsOf: sulfurArray)
    atomArray.append(contentsOf: othersArray)

    // Add atom identifiers codes in the right order (so atomArray[i] corresponds
    // has an atomIdentifiers[i] identifier.
    atomIdentifiers.append(contentsOf: Array(repeating: AtomType.CARBON, count: atomArrayComposition.carbonCount))
    atomIdentifiers.append(contentsOf: Array(repeating: AtomType.NITROGEN, count: atomArrayComposition.nitrogenCount))
    atomIdentifiers.append(contentsOf: Array(repeating: AtomType.HYDROGEN, count: atomArrayComposition.hydrogenCount))
    atomIdentifiers.append(contentsOf: Array(repeating: AtomType.OXYGEN, count: atomArrayComposition.oxygenCount))
    atomIdentifiers.append(contentsOf: Array(repeating: AtomType.SULFUR, count: atomArrayComposition.sulfurCount))
    atomIdentifiers.append(contentsOf: othersIDs)
    
    guard atomArray.count > 0 else {
        throw PDBParsingError.emptyAtomCount
    }

    return Protein(pdbID: pdbID,
                   description: description,
                   sourceLines: rawText.components(separatedBy: .newlines),
                   atoms: &atomArray,
                   atomArrayComposition: &atomArrayComposition,
                   atomIdentifiers: atomIdentifiers,
                   sequence: sequenceArray)
}
