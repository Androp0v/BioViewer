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
            } catch ImportError.emptyAtomCount {
                proteinViewModel?.statusFinished(withError: NSLocalizedString("Error: No ATOM data found in file", comment: ""))
                throw ImportError.emptyAtomCount
            } catch {
                proteinViewModel?.statusFinished(withError: NSLocalizedString("Error importing file", comment: ""))
                throw ImportError.unknownError
            }
        } else {
            proteinViewModel?.statusFinished(withError: NSLocalizedString("Unsupported file type", comment: ""))
            throw ImportError.unknownFileType
        }
    }
}
