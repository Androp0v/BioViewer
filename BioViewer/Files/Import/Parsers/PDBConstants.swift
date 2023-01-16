//
//  PDBConstants.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 11/12/21.
//

import Foundation

// MARK: - PDB Constants

enum PDBConstants {
    // Expected line length of a properly formatted PDB file
    // (hard to think of such a mythical creature).
    static let expectedLineLength: Int = 78
    
    // PDB ID location in HEADER record
    static let pdbIDStart: Int = 62
    static let pdbIDEnd: Int = 66
    
    // Spacing after the TITLE keyword in header until the start
    // of the data.
    static let titleKeywordLength: Int = 10

    // Start and end of the residue name
    static let resNameStart: Int = 17
    static let resNameEnd: Int = 20

    // Start and end of the residue identifier
    static let resIDStart: Int = 22
    static let resIDEnd: Int = 26

    // Start and end of the x coordinate positions
    static let xPositionStart: Int = 30
    static let xPositionEnd: Int = 38

    // Start and end of the y coordinate positions
    static let yPositionStart: Int = 38
    static let yPositionEnd: Int = 46

    // Start and end of the z coordinate positions
    static let zPositionStart: Int = 46
    static let zPositionEnd: Int = 54

    // Start and end of the element name
    static let elementStart: Int = 76
    static let elementEnd: Int = 78
}
