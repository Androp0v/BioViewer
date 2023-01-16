//
//  PDBParser.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 15/1/23.
//

import Foundation

private struct PDBAtomLine {
    let line: Int
    let atomType: UInt16
    let resID: Int
    let resType: Residue
    let position: simd_float3
}

private struct PDBModelStartLine {
    let line: Int
}

private struct PDBSubunitEndLine {
    let line: Int
}

private final class ParsedBlock {
    var atomRecords = [PDBAtomLine]()
    var modelStartRecord = [PDBModelStartLine]()
    var subunitEndRecords = [PDBSubunitEndLine]()
}

extension ParsedBlock {
    static func += (lhs: inout ParsedBlock, rhs: ParsedBlock) {
        lhs.atomRecords.append(contentsOf: rhs.atomRecords)
        lhs.modelStartRecord.append(contentsOf: rhs.modelStartRecord)
        lhs.subunitEndRecords.append(contentsOf: rhs.subunitEndRecords)
    }
}

class PDBParser {
    
    // MARK: - Configuration
    
    static let lineBlockSize: Int = 1024
    
    // MARK: - Parse PDB
    
    func parsePDB(
        fileName: String,
        fileExtension: String,
        byteSize: Int?,
        rawText: String,
        proteinViewModel: ProteinViewModel?,
        originalFileInfo: ProteinFileInfo? = nil
    ) async throws -> ProteinFile? {
        
        let rawLines = rawText.split(separator: "\n").map({ String($0) })
        let lineCount = rawLines.count
        let blockCount = Int(ceil(Double(lineCount) / Double(PDBParser.lineBlockSize)))
        
        // Create a TaskGroup so the file can be parsed simultaneously using multiple threads.
        await withTaskGroup(of: ParsedBlock.self) { taskGroup in
            // Lines to parse are batched into blocks to avoid creating too many tasks with
            // only minimal work per task.
            for blockIndex in 0..<blockCount {
                let startingLine: Int = blockIndex * PDBParser.lineBlockSize
                let endingLine: Int = min(startingLine + PDBParser.lineBlockSize, lineCount)
                
                taskGroup.addTask { [weak self] in
                    let parsedBlock = ParsedBlock()
                    for lineIndex in startingLine..<endingLine {
                        let rawLine = rawLines[lineIndex]
                        self?.parseLine(line: rawLine, lineIndex: lineIndex, in: parsedBlock)
                    }
                    return parsedBlock
                }
            }
            
            // Reduce the parsed blocks into a single one
            var parsedFile = ParsedBlock()
            for await parsedBlock in taskGroup {
                parsedFile += parsedBlock
            }
            
            // Create the objects
            let models = 
        }
        
        return nil
    }
    
    // MARK: - Parse line
    
    private func parseLine(line: String, lineIndex: Int, in parsedBlock: ParsedBlock) {
        if line.starts(with: "ATOM") || line.starts(with: "HETATM") {
            if let atom = try? parseAtom(line: line, lineIndex: lineIndex) {
                parsedBlock.atomRecords.append(atom)
            }
        } else if line.starts(with: "TER") {
            parsedBlock.subunitEndRecords.append(PDBSubunitEndLine(line: lineIndex))
        } else if line.starts(with: "MODEL") {
            parsedBlock.modelStartRecord.append(PDBModelStartLine(line: lineIndex))
        }
    }
    
    // MARK: - Parse ATOM/HETATM
    
    private func parseAtom(line: String, lineIndex: Int) throws -> PDBAtomLine? {
        // Check that the input line has the expected length (or more)
        // to avoid IndexOutOfRange exceptions.
        guard line.count >= PDBConstants.expectedLineLength else {
            throw PDBParseError.unexpectedLineLength
        }
        
        // Swift strings can't be indexed using Int and have to use Index
        // instead (since under the hood not all string characters are the
        // same length, due to Unicode and stuff).
        
        // Get residue id (1, 2, 3...) for current atom in the current chain
        let startResID = line.index(line.startIndex, offsetBy: PDBConstants.resIDStart)
        let endResID = line.index(line.startIndex, offsetBy: PDBConstants.resIDEnd)
        let rangeResID = startResID..<endResID
        let resID = Int( line[rangeResID].trimmingCharacters(in: .whitespaces) )
        guard let resID else {
            throw PDBParseError.missingResidueID
        }
        
        // Get residue name (ALA, GLN, LYS...) for current atom
        let startResName = line.index(line.startIndex, offsetBy: PDBConstants.resNameStart)
        let endResName = line.index(line.startIndex, offsetBy: PDBConstants.resNameEnd)
        let rangeResName = startResName..<endResName
        let resName = line[rangeResName].trimmingCharacters(in: .whitespaces)
        guard let resType = Residue(string: resName) else {
            throw PDBParseError.invalidResidueName
        }
        
        // Ignore water molecules
        // TODO: Option to toggle water visibility on/off
        if resName.contains("HOH") {
            return nil
        }
        
        // Get atom element
        let startElement = line.index(line.startIndex, offsetBy: PDBConstants.elementStart)
        let endElement = line.index(line.startIndex, offsetBy: PDBConstants.elementEnd)
        let rangeElement = startElement..<endElement
        let elementString = line[rangeElement].trimmingCharacters(in: .whitespaces)
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
            throw PDBParseError.invalidAtomCoordinates
        }
        
        // Since the projection matrix is left-handed, fix the chirality of the molecules
        z = -z
        
        return PDBAtomLine(
            line: lineIndex,
            atomType: element,
            resID: resID,
            resType: resType,
            position: simd_float3(x, y, z)
        )
    }
}
