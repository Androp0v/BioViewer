//
//  PDBParser.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 15/1/23.
//

import Foundation

// MARK: - Records

private struct PDBAtomLine {
    let line: Int
    let element: AtomElement
    let resID: Int
    let resType: Residue
    let position: simd_float3
}

private struct PDBModelEndLine {
    let line: Int
}

private struct PDBSubunitEndLine {
    let line: Int
}

private struct PDBTitleLine {
    let line: Int
    let rawText: String
}

private struct PDBAuthorLine {
    let line: Int
    let rawText: String
}

// MARK: - Blocks

private final class ParsedBlock {
    var pdbID: String?
    var titleRecords = [PDBTitleLine]()
    var authorRecords = [PDBAuthorLine]()
    var atomRecords = [PDBAtomLine]()
    var modelEndRecord = [PDBModelEndLine]()
    var subunitEndRecords = [PDBSubunitEndLine]()
}

extension ParsedBlock {
    static func += (lhs: inout ParsedBlock, rhs: ParsedBlock) {
        if let rhsPDBID = rhs.pdbID {
            lhs.pdbID = rhsPDBID
        }
        lhs.titleRecords.append(contentsOf: rhs.titleRecords)
        lhs.authorRecords.append(contentsOf: rhs.authorRecords)
        lhs.atomRecords.append(contentsOf: rhs.atomRecords)
        lhs.modelEndRecord.append(contentsOf: rhs.modelEndRecord)
        lhs.subunitEndRecords.append(contentsOf: rhs.subunitEndRecords)
    }
}

// MARK: - Models and subunits

private class ParsedModel {
    let startLine: Int
    let endLine: Int
    var subunits = [ParsedSubunit]()
    
    var atomPositions = [simd_float3]()
    var atomElements = [AtomElement]()
    var atomResType = [Residue]()
    
    init(startLine: Int, endLine: Int) {
        self.startLine = startLine
        self.endLine = endLine
    }
}

private class ParsedSubunit {
    let id = UUID()
    let isPartOfChain: Bool
    let startLine: Int
    let endLine: Int
    var atomCount: Int = 0
    
    init(startLine: Int, endLine: Int, isPartOfChain: Bool) {
        self.startLine = startLine
        self.endLine = endLine
        self.isPartOfChain = isPartOfChain
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
    ) async throws -> ProteinFile {
        
        let rawLines = rawText.split(separator: "\n").map({ String($0) })
        let lineCount = rawLines.count
        let blockCount = Int(ceil(Double(lineCount) / Double(PDBParser.lineBlockSize)))
        
        var finalProteins = [Protein]()
        let finalProteinInfo = originalFileInfo ?? ProteinFileInfo()

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
            var mergedBlocks = ParsedBlock()
            for await parsedBlock in taskGroup {
                mergedBlocks += parsedBlock
            }
            finalProteinInfo.pdbID = mergedBlocks.pdbID
            
            // Process file info
            if finalProteinInfo.description == nil {
                var descriptionText: String = ""
                for titleRecord in mergedBlocks.titleRecords.sorted(by: {$0.line < $1.line}) {
                    descriptionText += titleRecord.rawText
                }
                if !descriptionText.isEmpty {
                    finalProteinInfo.description = descriptionText
                }
            }
            if finalProteinInfo.authors == nil {
                var authorsText: String = ""
                for authorRecord in mergedBlocks.authorRecords.sorted(by: {$0.line < $1.line}) {
                    authorsText += authorRecord.rawText
                }
                if !authorsText.isEmpty {
                    finalProteinInfo.authors = authorsText
                }
            }
            
            // Number of MODELs (proteins) in the file. If empty, assume the entire
            // file contains a single protein model.
            var parsedModels = [ParsedModel]()
            if mergedBlocks.modelEndRecord.count == 0 {
                parsedModels.append(ParsedModel(startLine: 0, endLine: rawLines.count - 1))
            } else {
                let sortedModelRecords = mergedBlocks.modelEndRecord.sorted(by: { $0.line < $1.line })
                var lastModelStart: Int = 0
                for modelRecord in sortedModelRecords {
                    parsedModels.append(ParsedModel(
                        startLine: lastModelStart + 1,
                        endLine: modelRecord.line
                    ))
                    lastModelStart = modelRecord.line
                }
            }
            
            // Number of TER (subunits) in the file. If empty, assume there's at
            // least one subunit.
            if mergedBlocks.subunitEndRecords.count == 0 {
                for model in parsedModels {
                    model.subunits.append(ParsedSubunit(
                        startLine: model.startLine,
                        endLine: model.endLine,
                        isPartOfChain: true
                    ))
                }
            } else {
                let sortedSubunitRecords = mergedBlocks.subunitEndRecords.sorted(by: { $0.line < $1.line })
                for model in parsedModels {
                    var lastSubunitStart: Int = model.startLine
                    for subunitRecord in sortedSubunitRecords {
                        if subunitRecord.line >= model.startLine && subunitRecord.line <= model.endLine {
                            model.subunits.append(ParsedSubunit(
                                startLine: lastSubunitStart + 1,
                                endLine: subunitRecord.line,
                                isPartOfChain: true
                            ))
                            lastSubunitStart = subunitRecord.line
                        }
                    }
                }
            }
            
            // Sort all atom records
            mergedBlocks.atomRecords = mergedBlocks.atomRecords.sorted(by: { $0.line < $1.line })
                        
            // Use atom record data
            await withTaskGroup(of: Void.self) { [mergedBlocks] taskGroup in
                for model in parsedModels {
                    taskGroup.addTask {
                        let modelRecords = mergedBlocks.atomRecords.filter {
                            $0.line >= model.startLine && $0.line <= model.endLine
                        }
                        
                        // Add regular ATOM records if present
                        var lastParsedLine: Int = 0
                        for subunit in model.subunits {
                            let subunitRecords =  modelRecords.filter {
                                $0.line >= subunit.startLine && $0.line <= subunit.endLine
                            }
                            for record in subunitRecords {
                                model.atomPositions.append(record.position)
                                model.atomResType.append(record.resType)
                                model.atomElements.append(record.element)
                                lastParsedLine = record.line
                            }
                            subunit.atomCount = subunitRecords.count
                        }
                        
                        // Add non-chain HETATM records if present
                        let nonChainRecords = modelRecords.filter {
                            $0.line > lastParsedLine && $0.line < model.endLine
                        }
                        if !nonChainRecords.isEmpty,
                           let firstHETATMLine = nonChainRecords.first?.line,
                           let lastHETATMLine = nonChainRecords.last?.line {
                            let nonChainSubunit = ParsedSubunit(
                                startLine: firstHETATMLine,
                                endLine: lastHETATMLine,
                                isPartOfChain: false
                            )
                            model.subunits.append(nonChainSubunit)
                            for record in nonChainRecords {
                                model.atomPositions.append(record.position)
                                model.atomResType.append(record.resType)
                                model.atomElements.append(record.element)
                            }
                            nonChainSubunit.atomCount = nonChainRecords.count
                        }
                    }
                }
            }
            
            for model in parsedModels {
                var finalSubunits = [ProteinSubunit]()
                var subunitIndex = 0
                var atomIndex = 0
                for subunit in model.subunits {
                    finalSubunits.append(ProteinSubunit(
                        id: subunitIndex,
                        kind: subunit.isPartOfChain ? .chain : .nonChain,
                        atomCount: subunit.atomCount,
                        startIndex: atomIndex
                    ))
                    subunitIndex += 1
                    atomIndex += subunit.atomCount
                }
                
                let atomArrayComposition = AtomArrayComposition(elements: model.atomElements)
                
                finalProteins.append(Protein(
                    configurationCount: 1,
                    configurationEnergies: nil,
                    subunitCount: finalSubunits.count,
                    subunits: finalSubunits,
                    atoms: ContiguousArray(model.atomPositions),
                    atomArrayComposition: atomArrayComposition,
                    atomElements: model.atomElements,
                    atomResidues: model.atomResType
                ))
            }
            
        }
        
        return ProteinFile(
            fileType: .staticStructure,
            fileName: fileName,
            fileExtension: "pdb",
            models: finalProteins,
            fileInfo: finalProteinInfo,
            byteSize: byteSize
        )
    }
    
    // MARK: - Parse line
    
    private func parseLine(line: String, lineIndex: Int, in parsedBlock: ParsedBlock) {
        if line.starts(with: "ATOM") || line.starts(with: "HETATM") {
            if let atom = try? parseAtom(line: line, lineIndex: lineIndex) {
                parsedBlock.atomRecords.append(atom)
            }
        } else if line.starts(with: "TER") {
            parsedBlock.subunitEndRecords.append(PDBSubunitEndLine(line: lineIndex))
        } else if line.starts(with: "ENDMDL") {
            parsedBlock.modelEndRecord.append(PDBModelEndLine(line: lineIndex))
        } else if line.starts(with: "AUTHOR") {
            parsedBlock.authorRecords.append(parseAuthor(line: line, lineIndex: lineIndex))
        } else if line.starts(with: "TITLE") {
            parsedBlock.titleRecords.append(parseTitle(line: line, lineIndex: lineIndex))
        } else if line.starts(with: "HEADER") {
            parsedBlock.pdbID = parseHeader(line: line)
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
        let resType = Residue(string: resName)
        
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
        let element = AtomElement(string: elementString)
        
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
            element: element,
            resID: resID,
            resType: resType,
            position: simd_float3(x, y, z)
        )
    }
    
    // MARK: - Parse HEADER
    
    private func parseHeader(line: String) -> String {
        let startPDBID = line.index(line.startIndex, offsetBy: PDBConstants.pdbIDStart)
        let endPDBID = line.index(line.startIndex, offsetBy: PDBConstants.pdbIDEnd)
        let rangePDBID = startPDBID..<endPDBID
        return line[rangePDBID].trimmingCharacters(in: .whitespaces)
    }
    
    // MARK: - Parse TITLE
    
    private func parseTitle(line: String, lineIndex: Int) -> PDBTitleLine {
        var rawTitleLine = String(line.dropFirst(PDBConstants.titleKeywordLength))
        
        // Strip trailing newline
        rawTitleLine = String(rawTitleLine.trimmingCharacters(in: .newlines))
        
        // Strip trailing whitespaces
        while (rawTitleLine.last?.isWhitespace) ?? false {
            rawTitleLine = String(rawTitleLine.dropLast())
        }
        
        return PDBTitleLine(line: lineIndex, rawText: rawTitleLine)
    }
    
    // MARK: - Parse AUTHOR
    
    private func parseAuthor(line: String, lineIndex: Int) -> PDBAuthorLine {
        var rawTitleLine = String(line.dropFirst(PDBConstants.titleKeywordLength))
        
        // Strip trailing newline
        rawTitleLine = String(rawTitleLine.trimmingCharacters(in: .newlines))
        
        // Strip trailing whitespaces
        while (rawTitleLine.last?.isWhitespace) ?? false {
            rawTitleLine = String(rawTitleLine.dropLast())
        }
        
        return PDBAuthorLine(line: lineIndex, rawText: rawTitleLine)
    }
}
