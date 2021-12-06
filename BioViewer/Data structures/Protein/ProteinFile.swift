//
//  ProteinFile.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/12/21.
//

import Foundation

class ProteinFile {
    
    let fileName: String
    let fileExtension: String
    
    let protein: Protein
    let fileInfo: ProteinFileInfo
    
    init(fileName: String, fileExtension: String, protein: inout Protein, fileInfo: ProteinFileInfo) {
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.protein = protein
        self.fileInfo = fileInfo
    }
}
