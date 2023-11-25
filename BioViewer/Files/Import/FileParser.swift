//
//  FileParser.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 12/5/21.
//

import BioViewerFoundation
import Foundation
import PDBParser
import XYZParser

// MARK: - File parsing

class FileParser {
    func parseTextFile(
        rawText: String,
        fileName: String,
        fileExtension: String,
        byteSize: Int?,
        fileInfo: ProteinFileInfo?,
        statusViewModel: StatusViewModel,
        statusAction: StatusAction
    ) async throws -> ProteinFile {
        
        switch fileExtension {
        // MARK: - PDB Files
        case "pdb", "PDB", "pdb1", "PDB1":
            await statusViewModel.updateDescription(statusAction, description: "Importing file")
            do {
                let proteinFile = try await PDBParser().parsePDB(
                    fileName: fileName,
                    fileExtension: fileExtension,
                    byteSize: byteSize,
                    rawText: rawText,
                    progress: statusAction.progress ?? Progress(), // FIXME: This is a very hacky solution
                    originalFileInfo: fileInfo
                )
                return proteinFile
            } catch let error as ImportError {
                throw error
            } catch {
                throw ImportError.unknownError
            }
        // MARK: - XYZ Files
        case "xyz", "XYZ":
            await statusViewModel.updateDescription(statusAction, description: "Importing file")
            do {
                let proteinFile = try await XYZParser().parseXYZ(
                    fileName: fileName,
                    fileExtension: fileExtension,
                    byteSize: byteSize,
                    rawText: rawText,
                    progress: statusAction.progress ?? Progress(), // FIXME: This is a very hacky solution
                    originalFileInfo: fileInfo
                )
                return proteinFile
            } catch let error as ImportError {
                throw error
            } catch {
                throw ImportError.unknownError
            }
        // MARK: - Unknown Files
        default:
            throw ImportError.unknownFileType
        }
    }
}
