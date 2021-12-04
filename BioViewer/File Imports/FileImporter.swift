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
        let fileExtension = fileURL.pathExtension
        
        try importFileFromRawText(rawText: rawText,
                                  proteinViewModel: proteinViewModel,
                                  fileInfo: fileInfo,
                                  fileExtension: fileExtension.isEmpty ? nil : fileExtension)
    }
    
    static func importFileFromRawText(rawText: String, proteinViewModel: ProteinViewModel, fileInfo: ProteinFileInfo?, fileExtension: String?) throws {
        do {
            var protein = try FileParser().parseTextFile(rawText: rawText,
                                                         fileExtension: fileExtension,
                                                         fileInfo: fileInfo,
                                                         proteinViewModel: proteinViewModel)
            proteinViewModel.dataSource.addProteinToDataSource(protein: &protein, addToScene: true)
        } catch let error as ImportError {
            proteinViewModel.statusFinished(importError: error)
            throw error
        } catch {
            proteinViewModel.statusFinished(importError: ImportError.unknownError)
            throw error
        }
    }
}
