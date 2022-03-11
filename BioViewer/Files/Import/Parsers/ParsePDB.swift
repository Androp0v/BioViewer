//
//  ParsePDB.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/11/21.
//

import Foundation
import simd

class PDBParser {
    
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
    
    // MARK: - Properties
    
    private weak var proteinViewModel: ProteinViewModel?
    
    private var fileInfo: ProteinFileInfo?
    
    private var atomArray = ContiguousArray<simd_float3>()
    private var atomIdentifiers = [UInt8]()
    private var totalAtomArrayComposition = AtomArrayComposition()
    
    // Protein model list
    private var proteins = [Protein]()
    // Protein subunit list
    private var subunits: [ParsedSubunit] = [ParsedSubunit(id: 0)]
    
    private var subunitCount: Int = 0
    
    private var sequenceArray = [String]()
    private var sequenceIdentifiers = [Int]()

    private var currentResId: Int = -1
    private var currentLine: Int = 0
    
    // MARK: - Parse HEADER
    
    private func parseHeaderLine(line: String) {
        let startPDBID = line.index(line.startIndex, offsetBy: PDBConstants.pdbIdStart)
        let endPDBID = line.index(line.startIndex, offsetBy: PDBConstants.pdbIdEnd)
        let rangePDBID = startPDBID..<endPDBID

        let pdbIDString = line[rangePDBID].replacingOccurrences(of: " ", with: "")
        
        self.fileInfo?.pdbID = pdbIDString
    }
    
    // MARK: - Parse TITLE
    
    private func parseTitleLine(line: String) {
        var rawTitleLine = String(line.dropFirst(PDBConstants.titleKeywordLength))
        
        // Strip trailing newline
        rawTitleLine = String(rawTitleLine.trimmingCharacters(in: .newlines))
        
        // Strip trailing whitespaces
        while (rawTitleLine.last?.isWhitespace) ?? false {
            rawTitleLine = String(rawTitleLine.dropLast())
        }
        
        // Add to existing description or create a new one if empty
        if self.fileInfo?.description != nil {
            self.fileInfo?.description! += String(rawTitleLine)
        } else {
            self.fileInfo?.description = String(rawTitleLine)
            return
        }
    }
    
    // MARK: - Parse AUTHOR
    
    private func parseAuthorLine(line: String) {
        var rawAuthorLine = String(line.dropFirst(PDBConstants.titleKeywordLength))
        
        // Strip trailing newline
        rawAuthorLine = String(rawAuthorLine.trimmingCharacters(in: .newlines))
        
        // Strip trailing whitespaces
        while (rawAuthorLine.last?.isWhitespace) ?? false {
            rawAuthorLine = String(rawAuthorLine.dropLast())
        }
        
        // Add to existing description or create a new one if empty
        if self.fileInfo?.authors != nil {
            self.fileInfo?.authors! += String(rawAuthorLine)
        } else {
            self.fileInfo?.authors = String(rawAuthorLine)
            return
        }
    }
    
    // MARK: - Parse ATOM/HETATM
    
    private func parseAtom(line: String) {
        // Check that the input line has the expected length (or more)
        // to avoid IndexOutOfRange exceptions.
        guard line.count >= PDBConstants.expectedLineLength else {
            self.fileInfo?.warningIndices.append(self.currentLine)
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
            if self.currentResId != resId {
                self.currentResId = resId
                self.sequenceIdentifiers.append(resId)

                // Get residue name (ALA, GLN, LYS...) for current atom, now that we know it
                // belongs to a different residue than the last one.

                let startResName = line.index(line.startIndex, offsetBy: PDBConstants.resNameStart)
                let endResName = line.index(line.startIndex, offsetBy: PDBConstants.resNameEnd)
                let rangeResName = startResName..<endResName

                let resName = line[rangeResName].replacingOccurrences(of: " ", with: "")
                
                // Ignore water molecules
                if resName.contains("HOH") {
                    return
                }
                
                self.sequenceArray.append(resName)
            }
        } else {
            proteinViewModel?.statusViewModel.setWarning(
                warning: NSLocalizedString("Failed to identify residue ID for atom in line", comment: "") + " \(self.currentLine)."
            )
            self.fileInfo?.warningIndices.append(self.currentLine)
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
                                                         + " \(self.currentLine)"
                + " due to invalid coordinates."
            )
            self.fileInfo?.warningIndices.append(self.currentLine)
            return
        }

        // Save atom position to array based on element

        switch element {
        case AtomType.CARBON:
            self.subunits.last?.atomArrayComposition.carbonCount += 1
            self.subunits.last?.carbonArray.append(simd_float3(x, y, z))
        case AtomType.NITROGEN:
            self.subunits.last?.atomArrayComposition.nitrogenCount += 1
            self.subunits.last?.nitrogenArray.append(simd_float3(x, y, z))
        case AtomType.HYDROGEN:
            self.subunits.last?.atomArrayComposition.hydrogenCount += 1
            self.subunits.last?.hydrogenArray.append(simd_float3(x, y, z))
        case AtomType.OXYGEN:
            self.subunits.last?.atomArrayComposition.oxygenCount += 1
            self.subunits.last?.oxygenArray.append(simd_float3(x, y, z))
        case AtomType.SULFUR:
            self.subunits.last?.atomArrayComposition.sulfurCount += 1
            self.subunits.last?.sulfurArray.append(simd_float3(x, y, z))
        default:
            self.subunits.last?.atomArrayComposition.othersCount += 1
            self.subunits.last?.othersArray.append(simd_float3(x, y, z))
            self.subunits.last?.othersIDs.append(element)
        }
    }
    
    // MARK: - Create Protein object
    
    func createNewProtein() {
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
        
        if subunitCount == subunits.count - 1 {
            proteinViewModel?.statusViewModel.setWarning(warning:
                NSLocalizedString("No TER keyword found to mark the end of a chain, subunit count may be wrong", comment: "")
            )
            subunitCount += 1
        }
        
        let protein = Protein(configurationCount: 1,
                              configurationEnergies: nil,
                              subunitCount: proteinSubunits.count,
                              subunits: proteinSubunits,
                              atoms: &atomArray,
                              atomArrayComposition: &totalAtomArrayComposition,
                              atomIdentifiers: atomIdentifiers,
                              sequence: sequenceArray)
        
        proteins.append(protein)
        
        resetProteinVariables()
    }
    
    // MARK: - Create last protein
    
    private func createLastProteinIfNeeded() {
        if proteins.count == 0 {
            createNewProtein()
        }
    }
    
    // MARK: - Reset variables
    
    private func resetProteinVariables() {
        atomArray = ContiguousArray<simd_float3>()
        atomIdentifiers = [UInt8]()
        totalAtomArrayComposition = AtomArrayComposition()
        subunits = [ParsedSubunit(id: 0)]
        subunitCount = 0
        sequenceArray = [String]()
        sequenceIdentifiers = [Int]()
        currentResId = -1
    }
    
    // MARK: - Parse PDB
    
    func parsePDB(fileName: String, fileExtension: String, byteSize: Int?, rawText: String, proteinViewModel: ProteinViewModel?, originalFileInfo: ProteinFileInfo? = nil) throws -> ProteinFile {
        
        // Reference ProteinViewModel
        self.proteinViewModel = proteinViewModel
        
        // Protein file data
        fileInfo = ProteinFileInfo(pdbID: originalFileInfo?.pdbID,
                                   description: originalFileInfo?.description,
                                   authors: originalFileInfo?.authors,
                                   sourceLines: originalFileInfo?.sourceLines)
            
        let totalLineCount = rawText.reduce(into: 0) { (count, letter) in
           if letter == "\n" {
              count += 1
           }
        }
        
        var progress: Float {
            return Float(currentLine) / Float(totalLineCount)
        }
        
        // MARK: - Line iteration
        
        rawText.enumerateLines { [weak self] line, _ in
            
            guard let self = self else { return }
            
            self.currentLine += 1
            proteinViewModel?.statusProgress(progress: progress)
            
            // MARK: - HEADER
            
            // TO-DO: Do this in parallel with the ATOM decoding
            if line.starts(with: "HEADER") {
                guard originalFileInfo?.pdbID == nil else {
                    // We already know the PDB ID, don't overwrite it
                    return
                }
                self.parseHeaderLine(line: line)
            }
            
            // MARK: - TITLE
            
            // Try to retrieve the protein info from the headers
            // TO-DO: Do this in parallel with the ATOM decoding
            if line.starts(with: "TITLE") {
                guard originalFileInfo?.description == nil else {
                    // We already know the protein description, don't overwrite it
                    return
                }
                self.parseTitleLine(line: line)
            }
            
            // MARK: - AUTHOR
            
            // Retrieve authors
            // TO-DO: Do this in parallel with the ATOM decoding
            if line.starts(with: "AUTHOR") {
                guard originalFileInfo?.authors == nil else {
                    // We already know the PDB authors, don't overwrite them
                    return
                }
                self.parseAuthorLine(line: line)
            }
            
            // MARK: - TER
            
            // Check if this line marks the end of a subunit
            if line.starts(with: "TER") {
                self.subunitCount += 1
                self.subunits.append(ParsedSubunit(id: self.subunitCount))
            }
            
            // MARK: - ATOM/HETATM
            // We're only interested in the lines that contain atom positions
            if line.starts(with: "ATOM") || line.starts(with: "HETATM") {
                self.parseAtom(line: line)
            }
            
            // MARK: - ENDMDL
            if line.starts(with: "ENDMDL") {
                self.createNewProtein()
            }
        }
        
        // MARK: - Wrap-up
        
        createLastProteinIfNeeded()
        
        for protein in proteins {
            guard protein.atoms.count > 0 else {
                throw ImportError.emptyAtomCount
            }
        }
        
        fileInfo?.sourceLines = rawText.components(separatedBy: .newlines)
        
        return ProteinFile(fileType: .staticStructure,
                           fileName: fileName,
                           fileExtension: fileExtension,
                           models: proteins,
                           fileInfo: fileInfo!,
                           byteSize: byteSize)
    }
}
