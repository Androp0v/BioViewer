//
//  CIFParser.swift
//
//
//  Created by Raúl Montón Pinillos on 20/12/21.
//

import Foundation
import BioViewerFoundation
import simd

public actor CIFParser {
    
    final class ParsedData {
        var entryID: String?
    }
    
    class LoopMetadata {
        var categoryNames: [String]
        var values: [String: [String]]
        var willBeDiscarded: Bool
        
        init(loopCategoryNames: [String]) {
            self.categoryNames = loopCategoryNames
            self.values = [String: [String]]()
            self.willBeDiscarded = false
        }
    }
    
    // MARK: - Init
    
    public init() {}
        
    // MARK: - Parse header
    
    func parseEntryID(line: String) -> String? {
        guard let entryID = line.split(separator: " ")[safe: 1] else {
            return nil
        }
        return String(entryID)
    }
    
    // MARK: - Parse line
    
    func parseLine(line: String, into parsedData: inout ParsedData, allLoopMetadata: inout [LoopMetadata]) {
        
        guard !line.starts(with: Directives.comment) else {
            // Skip comment lines
            return
        }
        
        if line.starts(with: Directives.loop) {
            // loop_ directive within a loop means that a new loop started
            allLoopMetadata.append(LoopMetadata(loopCategoryNames: []))
            return
        }
        
        if let loopMetadata = allLoopMetadata.last {
            if line.starts(with: "_") {
                // Loop headers
                let categoryName = line.trimmingCharacters(in: .whitespacesAndNewlines)
                loopMetadata.categoryNames.append(categoryName)
                loopMetadata.values[categoryName] = []
            } else {
                // Loop data, all headers must have been read at this point
                if loopMetadata.willBeDiscarded {
                    return
                } else if loopMetadata.categoryNames.filter({ CategoryNames.categoriesToSave.contains($0)} ).count == 0 {
                    loopMetadata.willBeDiscarded = true
                    return
                }
                
                let lineValues = line.split(separator: " ")
                for (index, categoryName) in loopMetadata.categoryNames.enumerated() {
                    guard CategoryNames.categoriesToSave.contains(categoryName) else {
                        // Skip categories in which we're not interested
                        continue
                    }
                    if let categoryValue = lineValues[safe: index] {
                        loopMetadata.values[categoryName]?.append(String(categoryValue))
                    } else {
                        // TODO: Proper error handling
                        loopMetadata.values[categoryName]?.append("")
                    }
                }
            }
        } else {
            if line.starts(with: CategoryNames.Entry.id) {
                if let entryID = parseEntryID(line: line) {
                    parsedData.entryID = entryID
                }
            }
        }
    }
    
    // MARK: - Parse file
    
    public func parseCIF(
        fileName: String,
        fileExtension: String,
        byteSize: Int?,
        rawText: String,
        progress: Progress,
        originalFileInfo: ProteinFileInfo? = nil
    ) throws -> ProteinFile {
        
        var parsedData = ParsedData()
        
        // Protein file data
        var fileInfo = ProteinFileInfo(
            pdbID: originalFileInfo?.pdbID,
            description: originalFileInfo?.description,
            authors: originalFileInfo?.authors,
            sourceLines: originalFileInfo?.sourceLines
        )
        
        let rawLines = rawText.split(separator: "\n").map({ String($0) })
        
        var allLoopMetadata = [LoopMetadata]()
        for line in rawLines {
            parseLine(line: line, into: &parsedData, allLoopMetadata: &allLoopMetadata)
        }
         
        var models = [Protein]()
        for atomLoop in allLoopMetadata.filter({$0.categoryNames.contains(CategoryNames.AtomSite.groupPDB)}) {
            guard let rawAtomCount = atomLoop.values[CategoryNames.AtomSite.groupPDB]?.count,
                  let xValues = atomLoop.values[CategoryNames.AtomSite.cartnX],
                  let yValues = atomLoop.values[CategoryNames.AtomSite.cartnY],
                  let zValues = atomLoop.values[CategoryNames.AtomSite.cartnZ],
                  let elementValues = atomLoop.values[CategoryNames.AtomSite.typeSymbol],
                  xValues.count == rawAtomCount,
                  yValues.count == rawAtomCount,
                  zValues.count == rawAtomCount,
                  elementValues.count == rawAtomCount
            else {
                continue
            }
            let residueValues = atomLoop.values[CategoryNames.AtomSite.compID]
            let subunitValues = atomLoop.values[CategoryNames.AtomSite.authAsymID]
            
            var atoms = [simd_float3]()
            var elements = [AtomElement]()
            for index in 0..<rawAtomCount {
                guard let xValue = Float(xValues[index]),
                      let yValue = Float(yValues[index]),
                      var zValue = Float(zValues[index])
                else {
                    continue
                }
                if let residueValues, residueValues.count == rawAtomCount {
                    // Ignore water molecules
                    // TODO: Option to toggle water visibility on/off
                    guard residueValues[index] != "HOH" else {
                        continue
                    }
                }
                let element = elementValues[index]
                
                // Since the projection matrix is left-handed, fix the chirality of the molecules
                zValue = -zValue
                
                atoms.append(simd_float3(x: xValue, y: yValue, z: zValue))
                elements.append(AtomElement(string: element))
            }
            
            // Chains
            var chainIDs: [ChainID]?
            if let subunitValues, subunitValues.count == rawAtomCount {
                var tempChainIDs = [ChainID]()
                for index in 0..<rawAtomCount {
                    // Ignore water molecules
                    // TODO: Option to toggle water visibility on/off
                    if let residueValues, residueValues.count == rawAtomCount {
                        // Ignore water molecules
                        // TODO: Option to toggle water visibility on/off
                        guard residueValues[index] != "HOH" else {
                            continue
                        }
                    }
                    let rawChainID = subunitValues[index]
                    tempChainIDs.append(ChainID(string: rawChainID) ?? .zero)
                }
                chainIDs = tempChainIDs
            }
            
            // Residues
            var residues: [Residue]?
            if let residueValues, residueValues.count == rawAtomCount {
                var tempResidues = [Residue]()
                for index in 0..<rawAtomCount {
                    // Ignore water molecules
                    // TODO: Option to toggle water visibility on/off
                    guard residueValues[index] != "HOH" else {
                        continue
                    }
                    tempResidues.append(Residue(string: residueValues[index]))
                }
                residues = tempResidues
            }
            
            let protein = Protein(
                configurationCount: 1,
                configurationEnergies: nil,
                atoms: ContiguousArray(atoms),
                elementComposition: ProteinElementComposition(elements: elements),
                atomElements: elements,
                chainComposition: ProteinChainComposition(chainIDs: chainIDs),
                atomChainIDs: chainIDs,
                residueComposition: ProteinResidueComposition(residues: residues),
                atomResidues: residues,
                atomSecondaryStructure: nil
            )
            models.append(protein)
        }
        
        // Update file info with parsed data
        if fileInfo.pdbID == nil {
            fileInfo.pdbID = parsedData.entryID
        }
                
        return ProteinFile(
            fileType: .staticStructure,
            fileName: fileName,
            fileExtension: fileExtension,
            models: models,
            fileInfo: fileInfo,
            byteSize: byteSize
        )
    }
}

// MARK: - Extensions

fileprivate extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
