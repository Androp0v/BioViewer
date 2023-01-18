//
//  ParsePDB.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/11/21.
//

import Foundation
import simd

class LegacyPDBParser {
    
    private class ParsedSubunit {
        var id: Int
        var subunitAtomPositions = [simd_float3]()
        var subunitAtomTypes = [UInt16]()
        
        init(id: Int) {
            self.id = id
        }
    }
    
    // MARK: - Properties
    
    private weak var proteinViewModel: ProteinViewModel?
    
    private var fileInfo: ProteinFileInfo?
    
    // Protein model list
    private var proteins = [Protein]()
    
    private var currentAtomArray = ContiguousArray<simd_float3>()
    private var currentAtomIdentifiers = [UInt16]()
    private var currentTotalAtomArrayComposition = AtomArrayComposition()
    
    // Protein subunit list
    private var currentSubunits: [ParsedSubunit] = [ParsedSubunit(id: 0)]
    private var currentSubunitCount: Int = 0
    private var currentSequenceArray = [String]()
    private var currentSequenceIdentifiers = [Int]()
    
    private var currentResId: Int = -1
    private var currentLine: Int = 0
    
    // MARK: - Parse HEADER
    
    private func parseHeaderLine(line: String) {
        let startPDBID = line.index(line.startIndex, offsetBy: PDBConstants.pdbIDStart)
        let endPDBID = line.index(line.startIndex, offsetBy: PDBConstants.pdbIDEnd)
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
    
    // MARK: - Parse HELIX
    
    private func parseHelix(line: String) {
        
    }
    
    // MARK: - Parse SHEET
    
    private func parseSheet(line: String) {
        
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
        let startResId = line.index(line.startIndex, offsetBy: PDBConstants.resIDStart)
        let endResId = line.index(line.startIndex, offsetBy: PDBConstants.resIDEnd)
        let rangeResId = startResId..<endResId

        if let resId = Int( line[rangeResId].replacingOccurrences(of: " ", with: "") ) {
            // Avoid adding the residue id more than once
            if self.currentResId != resId {
                self.currentResId = resId
                self.currentSequenceIdentifiers.append(resId)

                // Get residue name (ALA, GLN, LYS...) for current atom, now that we know it
                // belongs to a different residue than the last one.

                let startResName = line.index(line.startIndex, offsetBy: PDBConstants.resNameStart)
                let endResName = line.index(line.startIndex, offsetBy: PDBConstants.resNameEnd)
                let rangeResName = startResName..<endResName

                let resName = line[rangeResName].replacingOccurrences(of: " ", with: "")
                
                // Ignore water molecules
                // TODO: Option to toggle water visibility on/off
                if resName.contains("HOH") {
                    return
                }
                
                self.currentSequenceArray.append(resName)
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
        let element = AtomTypeUtilities.getAtomId(atomName: String(elementString))

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
              var z = Float( line[rangeZ].replacingOccurrences(of: " ", with: "") )
        else {
            proteinViewModel?.statusViewModel.setWarning(warning:
                NSLocalizedString("Ignored atom in line", comment: "")
                                                         + " \(self.currentLine)"
                + " due to invalid coordinates."
            )
            self.fileInfo?.warningIndices.append(self.currentLine)
            return
        }
        
        // Since the projection matrix is left-handed, fix the chirality of the molecules
        z = -z

        // Save atom position to array
        self.currentSubunits.last?.subunitAtomTypes.append(element)
        self.currentSubunits.last?.subunitAtomPositions.append(simd_float3(x, y, z))
    }
    
    // MARK: - Create Protein object
    
    func createNewProtein() {
        // Add element array contents into the contiguous array
        var totalCount: Int = 0
        for subunit in currentSubunits {
            totalCount += subunit.subunitAtomPositions.count
        }
        currentAtomArray.reserveCapacity(MemoryLayout<simd_float3>.stride * totalCount)
        
        for subunit in currentSubunits {
            currentAtomArray.append(contentsOf: subunit.subunitAtomPositions)
            currentAtomIdentifiers.append(contentsOf: subunit.subunitAtomTypes)
        }
        
        for subunit in currentSubunits {
            currentTotalAtomArrayComposition += AtomArrayComposition(atomTypes: subunit.subunitAtomTypes)
        }
        
        var subunitIndex = 0
        var proteinSubunits = [ProteinSubunit]()
        for subunit in currentSubunits {
            // The last 'parsed' subunit may be empty, discard it
            guard subunit.subunitAtomPositions.count != 0 else {
                continue
            }
            proteinSubunits.append(ProteinSubunit(id: subunit.id,
                                                  atomCount: subunit.subunitAtomPositions.count,
                                                  startIndex: subunitIndex))
            subunitIndex += subunit.subunitAtomPositions.count
        }
        
        let protein = Protein(
            configurationCount: 1,
            configurationEnergies: nil,
            subunitCount: proteinSubunits.count,
            subunits: proteinSubunits,
            atoms: currentAtomArray,
            atomArrayComposition: currentTotalAtomArrayComposition,
            atomIdentifiers: currentAtomIdentifiers,
            atomResidues: nil,
            sequence: currentSequenceArray
        )
        
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
        currentAtomArray = ContiguousArray<simd_float3>()
        currentAtomIdentifiers = [UInt16]()
        currentTotalAtomArrayComposition = AtomArrayComposition()
        currentSubunits = [ParsedSubunit(id: 0)]
        currentSubunitCount = 0
        currentSequenceArray = [String]()
        currentSequenceIdentifiers = [Int]()
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
        for line in rawText.split(separator: "\n").map({ String($0) }) {
            currentLine += 1
            proteinViewModel?.statusProgress(progress: progress)
            
            if line.starts(with: "ATOM") || line.starts(with: "HETATM") {
                // MARK: - ATOM/HETATM
                
                parseAtom(line: line)
                
            } else if line.starts(with: "HELIX") {
                // MARK: - HELIX
                
                parseHelix(line: line)
                
            } else if line.starts(with: "SHEET") {
                // MARK: - SHEET
                
                parseSheet(line: line)
                
            } else if line.starts(with: "HEADER") {
                // MARK: - HEADER
                // TO-DO: Do this in parallel with the ATOM decoding
                
                guard originalFileInfo?.pdbID == nil else {
                    // We already know the PDB ID, don't overwrite it
                    continue
                }
                parseHeaderLine(line: line)
                
            } else if line.starts(with: "TITLE") {
                // MARK: - TITLE
                // Try to retrieve the protein info from the headers
                // TO-DO: Do this in parallel with the ATOM decoding

                guard originalFileInfo?.description == nil else {
                    // We already know the protein description, don't overwrite it
                    continue
                }
                parseTitleLine(line: line)
                
            } else if line.starts(with: "AUTHOR") {
                // MARK: - AUTHOR
                // Retrieve authors
                // TO-DO: Do this in parallel with the ATOM decoding
                
                guard originalFileInfo?.authors == nil else {
                    // We already know the PDB authors, don't overwrite them
                    continue
                }
                parseAuthorLine(line: line)
                
            } else if line.starts(with: "TER") {
                // MARK: - TER
                // Check if this line marks the end of a subunit
                currentSubunitCount += 1
                currentSubunits.append(ParsedSubunit(id: self.currentSubunitCount))
                
            } else if line.starts(with: "ENDMDL") {
                // MARK: - ENDMDL

                createNewProtein()
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
        
        return ProteinFile(
            fileType: .staticStructure,
            fileName: fileName,
            fileExtension: fileExtension,
            models: proteins,
            fileInfo: fileInfo!,
            byteSize: byteSize
        )
    }
}
