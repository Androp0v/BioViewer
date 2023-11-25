//
//  FileImporter.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 4/12/21.
//

import BioViewerFoundation
import Foundation

class FileImporter {
    
    static func importFromFileURL(
        fileURL: URL,
        proteinDataSource: ProteinDataSource,
        statusViewModel: StatusViewModel,
        fileInfo: ProteinFileInfo?
    ) async throws {
        
        let importStatusAction = StatusAction(
            type: .importFile,
            description: NSLocalizedString("Importing file", comment: ""),
            progress: nil
        )
        await statusViewModel.showStatusForAction(importStatusAction)
        
        guard let proteinData = try? Data(contentsOf: fileURL) else {
            await statusViewModel.signalActionFinished(importStatusAction, withError: ImportError.unknownError)
            throw ImportError.unknownError
        }
        
        let rawText = String(decoding: proteinData, as: UTF8.self)
        let fileName = fileURL.deletingPathExtension().lastPathComponent
        let fileExtension = fileURL.pathExtension
        
        guard !fileExtension.isEmpty else {
            await statusViewModel.signalActionFinished(importStatusAction, withError: ImportError.unknownError)
            throw ImportError.unknownFileExtension
        }
        
        let byteSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize
        
        try await importFileFromRawText(
            rawText: rawText,
            proteinDataSource: proteinDataSource,
            statusViewModel: statusViewModel,
            statusAction: importStatusAction,
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
        statusAction: StatusAction,
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
                statusViewModel: statusViewModel,
                statusAction: statusAction
            )
            await proteinDataSource.addProteinFileToDataSource(proteinFile: proteinFile)
            // File import finished
            await statusViewModel.signalActionFinished(statusAction, withError: nil)
        } catch let error as ImportError {
            await statusViewModel.signalActionFinished(statusAction, withError: error)
            throw error
        } catch {
            await statusViewModel.signalActionFinished(statusAction, withError: error)
            throw error
        }
    }
}
