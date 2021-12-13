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
    
    let fileType: ProteinFileType
    
    let fileName: String
    let fileExtension: String
    let byteSize: Int?
    
    let protein: Protein
    let fileInfo: ProteinFileInfo
    
    init(fileType: ProteinFileType, fileName: String, fileExtension: String, protein: inout Protein, fileInfo: ProteinFileInfo, byteSize: Int?) {
        self.fileType = fileType
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.protein = protein
        self.fileInfo = fileInfo
        self.byteSize = byteSize
    }
}
