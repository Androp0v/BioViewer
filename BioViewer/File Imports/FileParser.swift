//
//  FileParser.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 12/5/21.
//

import Foundation

// MARK: - File parsing

class FileParser {
    func parseTextFile(rawText: String, fileExtension: String?, proteinViewModel: ProteinViewModel?) throws -> Protein {

        if fileExtension == "pdb"
            || fileExtension == "PDB"
            || fileExtension == "pdb1"
            || fileExtension == "PDB1" {
            proteinViewModel?.statusUpdate(statusText: "Importing file")
            do {
                let protein = try parsePDB(rawText: rawText, proteinViewModel: proteinViewModel)
                return protein
            } catch let error as ImportError {
                proteinViewModel?.statusFinished(importError: error)
                throw ImportError.emptyAtomCount
            } catch {
                proteinViewModel?.statusFinished(importError: ImportError.unknownError)
                throw ImportError.unknownError
            }
        } else {
            proteinViewModel?.statusFinished(importError: ImportError.unknownFileType)
            throw ImportError.unknownFileType
        }
    }
}
