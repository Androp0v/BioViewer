//
//  ProteinSubunit.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 25/11/21.
//

import Foundation

/// Struct holding the contents of a protein subunit.
public class ProteinSubunit {
    
    public var id: Int

    // MARK: - Atoms
    
    /// Number of atoms in the subunit.
    public var atomCount: Int
    
    /// Index for the offset for the subunit atoms in the parent protein atom array.
    public var indexStart: Int
    
    // MARK: - Initialization
    
    init(id: Int, atomCount: Int, indexStart: Int) {
        self.id = id
        self.atomCount = atomCount
        self.indexStart = indexStart
    }
}
