//
//  FileImporter.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 4/12/21.
//

import Foundation

class FileImporter {
    
    static func importFromFileURL(fileURL: URL, proteinViewModel: ProteinViewModel, fileInfo: ProteinFileInfo?) throws {
        
        guard let proteinData = try? Data(contentsOf: fileURL) else {
            proteinViewModel.statusFinished(importError: ImportError.unknownError)
            throw ImportError.unknownError
        }
        
        proteinViewModel.statusUpdate(statusText: NSLocalizedString("Importing file", comment: ""))
        
        let rawText = String(decoding: proteinData, as: UTF8.self)
        let fileName = fileURL.deletingPathExtension().lastPathComponent
        let fileExtension = fileURL.pathExtension
        
        guard !fileExtension.isEmpty else {
            proteinViewModel.statusFinished(importError: ImportError.unknownError)
            throw ImportError.unknownFileExtension
        }
        
        let byteSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize
        
        try importFileFromRawText(rawText: rawText,
                                  proteinViewModel: proteinViewModel,
                                  fileInfo: fileInfo,
                                  fileName: fileName,
                                  fileExtension: fileExtension,
                                  byteSize: byteSize)
    }
    
    static func importFileFromRawText(rawText: String, proteinViewModel: ProteinViewModel, fileInfo: ProteinFileInfo?, fileName: String, fileExtension: String, byteSize: Int?) throws {
        do {
            let proteinFile = try FileParser().parseTextFile(rawText: rawText,
                                                             fileName: fileName,
                                                             fileExtension: fileExtension,
                                                             byteSize: byteSize,
                                                             fileInfo: fileInfo,
                                                             proteinViewModel: proteinViewModel)
            proteinViewModel.dataSource.addProteinFileToDataSource(proteinFile: proteinFile, addToScene: true)
        } catch let error as ImportError {
            proteinViewModel.statusFinished(importError: error)
            throw error
        } catch {
            proteinViewModel.statusFinished(importError: ImportError.unknownError)
            throw error
        }
    }
}
