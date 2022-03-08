//
//  ProteinFile.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/12/21.
//

import Foundation

// MARK: - ProteinFileType
enum ProteinFileType {
    case staticStructure
    case dynamicStructure
}

// MARK: - ProteinFile

class ProteinFile {
    
    /// Unique ID for the file (only used internally).
    let fileID = ProteinFile.randomID()
    
    /// The type of protein file type (whether it contains a static structure or several configurations of the same protein).
    let fileType: ProteinFileType
    /// Name of the protein file.
    let fileName: String
    /// Extension of the protein file (.pdb, .cif...).
    let fileExtension: String
    /// Size of the stored file, in bytes.
    let byteSize: Int?
    /// File metadata.
    let fileInfo: ProteinFileInfo
    
    /// Protein contained in the file.
    let models: [Protein]
    
    init(fileType: ProteinFileType, fileName: String, fileExtension: String, models: [Protein], fileInfo: ProteinFileInfo, byteSize: Int?) {
        self.fileType = fileType
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.models = models
        self.fileInfo = fileInfo
        self.byteSize = byteSize
    }
    
    // MARK: - Private
    static private func randomID() -> String {
        
        let randomID = NSMutableString(capacity: 32)
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        for _ in 0..<32 {
            let randomCharacter = String(characters.randomElement() ?? "0")
            randomID.appending(randomCharacter)
        }
        return String(randomID)
    }
}
