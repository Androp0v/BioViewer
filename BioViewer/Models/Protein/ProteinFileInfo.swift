//
//  ProteinFileInfo.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 14/11/21.
//

import Foundation

/// Class containing the data related to the imported protein file itself.
struct ProteinFileInfo {
    
    /// PDB ID as in RCSB database.
    var pdbID: String?
    /// Human-readable description of the protein.
    var description: String?
    /// Authors of the file.
    var authors: String?
    /// Full source file text
    var sourceLines: [String]?
    
    /// List of all lines with warnings
    var warningIndices: [Int] = []
    
    // MARK: - Initialization
    
    init() {}
    
    init(pdbID: String?, description: String?, authors: String?, sourceLines: [String]?) {
        self.pdbID = pdbID
        self.description = description
        self.authors = authors
        self.sourceLines = sourceLines
    }
}
