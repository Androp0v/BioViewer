//
//  FileParser.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 12/5/21.
//

import Foundation

// MARK: - File parsing

class FileParser {
    func parseTextFile(
        rawText: String,
        fileName: String,
        fileExtension: String,
        byteSize: Int?,
        fileInfo: ProteinFileInfo?,
        statusViewModel: StatusViewModel
    ) async throws -> ProteinFile {
        
        switch fileExtension {
        // MARK: - PDB Files
        case "pdb", "PDB", "pdb1", "PDB1":
            await statusViewModel.statusUpdate(statusText: "Importing file")
            do {
                let proteinFile = try await PDBParser().parsePDB(
                    fileName: fileName,
                    fileExtension: fileExtension,
                    byteSize: byteSize,
                    rawText: rawText,
                    originalFileInfo: fileInfo
                )
                return proteinFile
            } catch let error as ImportError {
                await statusViewModel.statusFinished(importError: error)
                throw ImportError.emptyAtomCount
            } catch {
                await statusViewModel.statusFinished(importError: ImportError.unknownError)
                throw ImportError.unknownError
            }
        // MARK: - XYZ Files
        case "xyz", "XYZ":
            await statusViewModel.statusUpdate(statusText: "Importing file")
            do {
                let proteinFile = try parseXYZ(
                    fileName: fileName,
                    fileExtension: fileExtension,
                    byteSize: byteSize,
                    rawText: rawText,
                    statusViewModel: statusViewModel,
                    originalFileInfo: fileInfo
                )
                return proteinFile
            } catch let error as ImportError {
                await statusViewModel.statusFinished(importError: error)
                throw ImportError.emptyAtomCount
            } catch {
                await statusViewModel.statusFinished(importError: ImportError.unknownError)
                throw ImportError.unknownError
            }
        // MARK: - Unknown Files
        default:
            await statusViewModel.statusFinished(importError: ImportError.unknownFileType)
            throw ImportError.unknownFileType
        }
    }
}
