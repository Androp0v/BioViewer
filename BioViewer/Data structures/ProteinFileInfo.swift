//
//  ProteinFileInfo.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 14/11/21.
//

import Foundation

/// Class containing the data related to the imported protein file itself.
public class ProteinFileInfo {
    
    /// PDB ID as in RCSB database.
    public var pdbID: String?
    /// Human-readable description of the protein.
    public var description: String?
    /// Authors of the file.
    public var authors: String?
    /// Full source file text
    public var sourceLines: [String]?
    
    /// List of all lines with warnings
    public var warningIndices: [Int] = []
    
    // MARK: - Initialization
    
    init() {}
    
    init(pdbID: String?, description: String?, authors: String?, sourceLines: [String]?) {
        self.pdbID = pdbID
        self.description = description
        self.sourceLines = sourceLines
    }
    
}
