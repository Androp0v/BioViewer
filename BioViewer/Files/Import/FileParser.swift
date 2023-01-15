//
//  FileParser.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 12/5/21.
//

import Foundation

// MARK: - File parsing

class FileParser {
    func parseTextFile(rawText: String, fileName: String, fileExtension: String, byteSize: Int?, fileInfo: ProteinFileInfo?, proteinViewModel: ProteinViewModel?) throws -> ProteinFile {
        
        switch fileExtension {
        // MARK: - PDB Files
        case "pdb", "PDB", "pdb1", "PDB1":
            proteinViewModel?.statusUpdate(statusText: "Importing file")
            do {
                let proteinFile = try LegacyPDBParser().parsePDB(fileName: fileName,
                                                           fileExtension: fileExtension,
                                                           byteSize: byteSize,
                                                           rawText: rawText,
                                                           proteinViewModel: proteinViewModel,
                                                           originalFileInfo: fileInfo)
                return proteinFile
            } catch let error as ImportError {
                proteinViewModel?.statusFinished(importError: error)
                throw ImportError.emptyAtomCount
            } catch {
                proteinViewModel?.statusFinished(importError: ImportError.unknownError)
                throw ImportError.unknownError
            }
        // MARK: - XYZ Files
        case "xyz", "XYZ":
            proteinViewModel?.statusUpdate(statusText: "Importing file")
            do {
                let proteinFile = try parseXYZ(fileName: fileName,
                                               fileExtension: fileExtension,
                                               byteSize: byteSize,
                                               rawText: rawText,
                                               proteinViewModel: proteinViewModel,
                                               originalFileInfo: fileInfo)
                return proteinFile
            } catch let error as ImportError {
                proteinViewModel?.statusFinished(importError: error)
                throw ImportError.emptyAtomCount
            } catch {
                proteinViewModel?.statusFinished(importError: ImportError.unknownError)
                throw ImportError.unknownError
            }
        // MARK: - Unknown Files
        default:
            proteinViewModel?.statusFinished(importError: ImportError.unknownFileType)
            throw ImportError.unknownFileType
        }
    }
}
