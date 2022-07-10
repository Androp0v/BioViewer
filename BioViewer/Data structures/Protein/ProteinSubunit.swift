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
    public var startIndex: Int
    
    // MARK: - Initialization
    
    init(id: Int, atomCount: Int, startIndex: Int) {
        self.id = id
        self.atomCount = atomCount
        self.startIndex = startIndex
    }
    
    // MARK: - Functions
    func getUppercaseName() -> String {
        let letters = ["A",
                       "B",
                       "C",
                       "D",
                       "E",
                       "F",
                       "G",
                       "H",
                       "I",
                       "J",
                       "K",
                       "L",
                       "M",
                       "N",
                       "O",
                       "P",
                       "Q",
                       "R",
                       "S",
                       "T",
                       "U",
                       "V",
                       "W",
                       "X",
                       "Y",
                       "Z"]
        if id < 26 {
            return letters[id]
        } else {
            return String(id)
        }
    }
}
