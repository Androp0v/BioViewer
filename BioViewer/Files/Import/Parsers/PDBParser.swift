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
    let chainID: String
    let resID: Int
    let resType: Residue
    let position: simd_float3
}

protocol PDBSecondaryStructureLine {
    var line: Int { get }
    var initChainID: String { get }
    var initResID: Int { get }
    var finalChainID: String { get }
    var finalResID: Int { get }
    var underlyingType: SecondaryStructure { get }
}

private struct PDBHelixLine: PDBSecondaryStructureLine {
    let line: Int
    let initChainID: String
    let initResID: Int
    let finalChainID: String
    let finalResID: Int
    let underlyingType: SecondaryStructure = .helix
}

private struct PDBSheetLine: PDBSecondaryStructureLine {
    let line: Int
    let initChainID: String
    let initResID: Int
    let finalChainID: String
    let finalResID: Int
    let underlyingType: SecondaryStructure = .sheet
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
    var helixRecords = [PDBHelixLine]()
    var sheetRecords = [PDBSheetLine]()
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
        lhs.helixRecords.append(contentsOf: rhs.helixRecords)
        lhs.sheetRecords.append(contentsOf: rhs.sheetRecords)
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
    var atomResidues = [Residue]()
    var atomSecondaryStructure = [SecondaryStructure]()
    
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

private class SecondaryStructureIterator {
    private let helixRecords: [PDBHelixLine]
    private let sheetRecords: [PDBSheetLine]
    private var currentHelixIndex: Int = -1
    private var finishedCurrentHelix: Bool = false
    private var currentSheetIndex: Int = -1
    private var finishedCurrentSheet: Bool = false
    private var lastChainID: String?
    private var lastResID: Int?
    
    init(helixRecords: [PDBHelixLine], sheetRecords: [PDBSheetLine]) {
        self.helixRecords = helixRecords.sorted(by: { lhsHelix, rhsHelix in
            if lhsHelix.initChainID == rhsHelix.initChainID {
                return lhsHelix.initResID < rhsHelix.initResID
            }
            return false
        })
        self.sheetRecords = sheetRecords.sorted(by: { lhsSheet, rhsSheet in
            if lhsSheet.initChainID == rhsSheet.initChainID {
                return lhsSheet.initResID < rhsSheet.initResID
            }
            return false
        })
    }
    
    private func getCurrentHelix() -> PDBHelixLine? {
        if currentHelixIndex >= 0 && !finishedCurrentHelix {
            return helixRecords[currentHelixIndex]
        }
        return nil
    }
    private func getCurrentSheet() -> PDBSheetLine? {
        if currentSheetIndex >= 0 && !finishedCurrentSheet {
            return sheetRecords[currentSheetIndex]
        }
        return nil
    }
    private func getCurrentStructure() -> (any PDBSecondaryStructureLine)? {
        if currentHelixIndex >= 0 && !finishedCurrentHelix {
            return helixRecords[currentHelixIndex]
        }
        if currentSheetIndex >= 0 && !finishedCurrentSheet {
            return sheetRecords[currentSheetIndex]
        }
        return nil
    }
    private func getNextHelix() -> (any PDBSecondaryStructureLine)? {
        guard currentHelixIndex + 1 < helixRecords.count else { return nil }
        return helixRecords[currentHelixIndex + 1]
    }
    private func getNextSheet() -> (any PDBSecondaryStructureLine)? {
        guard currentSheetIndex + 1 < sheetRecords.count else { return nil }
        return sheetRecords[currentSheetIndex + 1]
    }
    private func goToNextHelix() {
        finishedCurrentHelix = false
        currentHelixIndex += 1
    }
    private func goToNextSheet() {
        finishedCurrentSheet = false
        currentSheetIndex += 1
    }
    
    func advanceAndGetCurrentStructure(chainID: String, resID: Int) -> SecondaryStructure {
        if let currentHelix = getCurrentHelix(),
           lastChainID == currentHelix.finalChainID
            && lastResID == currentHelix.finalResID
            && (chainID != lastChainID || resID != lastResID) {
            // Outside the bounds of last helix
            finishedCurrentHelix = true
        }
        if let currentSheet = getCurrentSheet(),
           lastChainID == currentSheet.finalChainID
            && lastResID == currentSheet.finalResID
            && (chainID != lastChainID || resID != lastResID) {
            // Outside the bounds of last sheet
            finishedCurrentSheet = true
        }
        
        var returnValue: SecondaryStructure = .loop
        
        if let currentStructure = getCurrentStructure() {
            var insideNextHelix: Bool = false
            var insideNextSheet: Bool = false
            if let nextHelix = getNextHelix(),
               chainID == nextHelix.initChainID
                && resID == nextHelix.initResID {
                // Inside the bounds of next helix, without finishing the last structure
                insideNextHelix = true
                goToNextHelix()
                returnValue = .helix
            }
            if let nextSheet = getNextSheet(),
               chainID == nextSheet.initChainID
                && resID == nextSheet.initResID {
                // Inside the bounds of next sheet, without finishing the last structure
                insideNextSheet = true
                goToNextSheet()
                returnValue = .sheet
            }
            if !insideNextHelix && !insideNextSheet {
                // Still inside last structure
                returnValue = currentStructure.underlyingType
            }
        } else {
            // Check if we're now inside the bounds of the next structure
            if let nextHelix = getNextHelix(),
               chainID == nextHelix.initChainID
                && resID == nextHelix.initResID {
                // Inside the bounds of next structure
                goToNextHelix()
                returnValue = .helix
            }
            if let nextSheet = getNextSheet(),
               chainID == nextSheet.initChainID
                && resID == nextSheet.initResID {
                // Inside the bounds of next structure
                goToNextSheet()
                returnValue = .sheet
            }
        }
        // All other cases: we must be in a loop
        lastChainID = chainID
        lastResID = resID
        return returnValue
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
            finalProteinInfo.sourceLines = rawLines
            
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
                        // FIXME: mergedBlocks -> something dependent on model
                        let structureIterator = SecondaryStructureIterator(
                            helixRecords: mergedBlocks.helixRecords,
                            sheetRecords: mergedBlocks.sheetRecords
                        )
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
                                model.atomResidues.append(record.resType)
                                model.atomElements.append(record.element)
                                let structure = structureIterator.advanceAndGetCurrentStructure(
                                    chainID: record.chainID,
                                    resID: record.resID
                                )
                                model.atomSecondaryStructure.append(structure)
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
                                model.atomResidues.append(record.resType)
                                model.atomElements.append(record.element)
                                model.atomSecondaryStructure.append(.nonChain)
                            }
                            nonChainSubunit.atomCount = nonChainRecords.count
                        }
                    }
                }
            }
            
            // Convert parsed objects to final objects
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
                
                let elementComposition = ProteinElementComposition(elements: model.atomElements)
                let residueComposition = ProteinResidueComposition(residues: model.atomResidues)
                
                finalProteins.append(Protein(
                    configurationCount: 1,
                    configurationEnergies: nil,
                    subunitCount: finalSubunits.count,
                    subunits: finalSubunits,
                    atoms: ContiguousArray(model.atomPositions),
                    elementComposition: elementComposition,
                    atomElements: model.atomElements,
                    residueComposition: residueComposition,
                    atomResidues: model.atomResidues,
                    atomSecondaryStructure: model.atomSecondaryStructure
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
        } else if line.starts(with: "HELIX") {
            if let helix = try? parseHelix(line: line, lineIndex: lineIndex) {
                parsedBlock.helixRecords.append(helix)
            }
        } else if line.starts(with: "SHEET") {
            if let sheet = try? parseSheet(line: line, lineIndex: lineIndex) {
                parsedBlock.sheetRecords.append(sheet)
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
        
        let chainID = extract(from: line, range: PDBConstants.AtomRecord.chainIDRange)
        
        // Get residue id (1, 2, 3...) for current atom in the current chain
        let startResID = line.index(line.startIndex, offsetBy: PDBConstants.AtomRecord.resIDStart)
        let endResID = line.index(line.startIndex, offsetBy: PDBConstants.AtomRecord.resIDEnd)
        let rangeResID = startResID..<endResID
        let resID = Int( line[rangeResID].trimmingCharacters(in: .whitespaces) )
        guard let resID else {
            throw PDBParseError.missingResidueID
        }
        
        // Get residue name (ALA, GLN, LYS...) for current atom
        let startResName = line.index(line.startIndex, offsetBy: PDBConstants.AtomRecord.resNameStart)
        let endResName = line.index(line.startIndex, offsetBy: PDBConstants.AtomRecord.resNameEnd)
        let rangeResName = startResName..<endResName
        let resName = line[rangeResName].trimmingCharacters(in: .whitespaces)
        let resType = Residue(string: resName)
        
        // Ignore water molecules
        // TODO: Option to toggle water visibility on/off
        if resName.contains("HOH") {
            return nil
        }
        
        // Get atom element
        let startElement = line.index(line.startIndex, offsetBy: PDBConstants.AtomRecord.elementStart)
        let endElement = line.index(line.startIndex, offsetBy: PDBConstants.AtomRecord.elementEnd)
        let rangeElement = startElement..<endElement
        let elementString = line[rangeElement].trimmingCharacters(in: .whitespaces)
        let element = AtomElement(string: elementString)
        
        // Get atom coordinates
        let startX = line.index(line.startIndex, offsetBy: PDBConstants.AtomRecord.xPositionStart)
        let endX = line.index(line.startIndex, offsetBy: PDBConstants.AtomRecord.xPositionEnd)
        let rangeX = startX..<endX

        let startY = line.index(line.startIndex, offsetBy: PDBConstants.AtomRecord.yPositionStart)
        let endY = line.index(line.startIndex, offsetBy: PDBConstants.AtomRecord.yPositionEnd)
        let rangeY = startY..<endY

        let startZ = line.index(line.startIndex, offsetBy: PDBConstants.AtomRecord.zPositionStart)
        let endZ = line.index(line.startIndex, offsetBy: PDBConstants.AtomRecord.zPositionEnd)
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
            chainID: chainID,
            resID: resID,
            resType: resType,
            position: simd_float3(x, y, z)
        )
    }
    
    // MARK: - Parse HELIX
    
    private func parseHelix(line: String, lineIndex: Int) throws -> PDBHelixLine {
        // Get chain id (1, 2, 3...) for initial chain in helix
        let initChainID = extract(
            from: line,
            range: PDBConstants.HelixRecord.initChainIDRange
        )
        // Get residue id (1, 2, 3...) for initial residue in helix
        let initResID = Int( extract(
            from: line,
            range: PDBConstants.HelixRecord.initResIDRange)
        )
        guard let initResID else {
            throw PDBParseError.missingHELIXInitResidueID
        }
        // Get residue id (1, 2, 3...) for final residue in helix
        let finalResID = Int( extract(
            from: line,
            range: PDBConstants.HelixRecord.finalResIDRange)
        )
        guard let finalResID else {
            throw PDBParseError.missingHELIXFinalResidueID
        }
        // Get chain id (1, 2, 3...) for initial chain in helix
        let finalChainID = extract(
            from: line,
            range: PDBConstants.HelixRecord.finalChainIDRange
        )
        
        return PDBHelixLine(
            line: lineIndex,
            initChainID: initChainID,
            initResID: initResID,
            finalChainID: finalChainID,
            finalResID: finalResID
        )
    }
    
    // MARK: - Parse SHEET
    
    private func parseSheet(line: String, lineIndex: Int) throws -> PDBSheetLine {
        // Get chain id (1, 2, 3...) for initial chain in helix
        let initChainID = extract(
            from: line,
            range: PDBConstants.SheetRecord.initChainIDRange
        )
        // Get residue id (1, 2, 3...) for initial residue in helix
        let initResID = Int( extract(
            from: line,
            range: PDBConstants.SheetRecord.initResIDRange)
        )
        guard let initResID else {
            throw PDBParseError.missingHELIXInitResidueID
        }
        // Get residue id (1, 2, 3...) for final residue in helix
        let finalResID = Int( extract(
            from: line,
            range: PDBConstants.SheetRecord.finalResIDRange)
        )
        guard let finalResID else {
            throw PDBParseError.missingHELIXFinalResidueID
        }
        // Get chain id (1, 2, 3...) for initial chain in helix
        let finalChainID = extract(
            from: line,
            range: PDBConstants.SheetRecord.finalChainIDRange
        )
        
        return PDBSheetLine(
            line: lineIndex,
            initChainID: initChainID,
            initResID: initResID,
            finalChainID: finalChainID,
            finalResID: finalResID
        )
    }
    
    // MARK: - Parse HEADER
    
    private func parseHeader(line: String) -> String {
        let startPDBID = line.index(line.startIndex, offsetBy: PDBConstants.HeaderRecord.pdbIDStart)
        let endPDBID = line.index(line.startIndex, offsetBy: PDBConstants.HeaderRecord.pdbIDEnd)
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
    
    // MARK: - Utility func
    func extract(from line: String, range: Range<Int>) -> String {
        let startIndex = line.index(line.startIndex, offsetBy: range.startIndex)
        let endIndex = line.index(line.startIndex, offsetBy: range.endIndex)
        let stringRange = startIndex..<endIndex
        return line[stringRange].trimmingCharacters(in: .whitespaces)
    }
}
