//
//  FileImporter.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 4/12/21.
//

import Foundation

class FileImporter {
    
    static func importFromFileURL(
        fileURL: URL,
        proteinDataSource: ProteinDataSource,
        statusViewModel: StatusViewModel,
        fileInfo: ProteinFileInfo?
    ) async throws {
        
        guard let proteinData = try? Data(contentsOf: fileURL) else {
            statusViewModel.statusFinished(importError: ImportError.unknownError)
            throw ImportError.unknownError
        }
        
        statusViewModel.statusUpdate(statusText: NSLocalizedString("Importing file", comment: ""))
        
        let rawText = String(decoding: proteinData, as: UTF8.self)
        let fileName = fileURL.deletingPathExtension().lastPathComponent
        let fileExtension = fileURL.pathExtension
        
        guard !fileExtension.isEmpty else {
            statusViewModel.statusFinished(importError: ImportError.unknownError)
            throw ImportError.unknownFileExtension
        }
        
        let byteSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize
        
        try await importFileFromRawText(
            rawText: rawText,
            proteinDataSource: proteinDataSource,
            statusViewModel: statusViewModel,
            fileInfo: fileInfo,
            fileName: fileName,
            fileExtension: fileExtension,
            byteSize: byteSize
        )
    }
    
    static func importFileFromRawText(
        rawText: String,
        proteinDataSource: ProteinDataSource,
        statusViewModel: StatusViewModel,
        fileInfo: ProteinFileInfo?,
        fileName: String,
        fileExtension: String,
        byteSize: Int?
    ) async throws {
        do {
            let proteinFile = try await FileParser().parseTextFile(
                rawText: rawText,
                fileName: fileName,
                fileExtension: fileExtension,
                byteSize: byteSize,
                fileInfo: fileInfo,
                statusViewModel: statusViewModel
            )
            await proteinDataSource.addProteinFileToDataSource(proteinFile: proteinFile)
            // File import finished
            statusViewModel.statusFinished(action: StatusAction.importFile)
        } catch let error as ImportError {
            statusViewModel.statusFinished(importError: error)
            throw error
        } catch {
            statusViewModel.statusFinished(importError: ImportError.unknownError)
            throw error
        }
    }
}
