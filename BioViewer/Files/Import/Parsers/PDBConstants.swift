//
//  PDBConstants.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 11/12/21.
//

import Foundation

// MARK: - PDB Constants

enum PDBConstants {
    /// Expected line length of a properly formatted PDB file (hard to think of such a mythical creature).
    static let expectedLineLength: Int = 78
    
    /// Spacing after the TITLE keyword in header until the start of the data.
    static let titleKeywordLength: Int = 10
    
    enum HeaderRecord {
        /// Start column position of the PDB ID in HEADER record.
        static let pdbIDStart: Int = 62
        /// End column position of the PDB ID in HEADER record.
        static let pdbIDEnd: Int = 66
    }
    
    enum AtomRecord {
        /// Start column position of the residue name.
        static let resNameStart: Int = 17
        /// End column position of the residue name.
        static let resNameEnd: Int = 20
        
        /// Column index range of the chainID where the helix starts.
        static let chainIDRange: Range<Int> = 21..<22
        
        /// Start column position of the residue identifier.
        static let resIDStart: Int = 22
        /// End column position of the residue identifier.
        static let resIDEnd: Int = 26
        
        /// Start column position of the x coordinate positions.
        static let xPositionStart: Int = 30
        /// End column position of the x coordinate positions.
        static let xPositionEnd: Int = 38
        
        /// Start column position of the y coordinate positions.
        static let yPositionStart: Int = 38
        /// End column position of the y coordinate positions.
        static let yPositionEnd: Int = 46
        
        /// Start column position of the z coordinate positions.
        static let zPositionStart: Int = 46
        /// End column position of the z coordinate positions.
        static let zPositionEnd: Int = 54
        
        /// Start column position of the element name.
        static let elementStart: Int = 76
        /// End column position of the element name.
        static let elementEnd: Int = 78
    }
    
    enum HelixRecord {
        /// Column index range of the chainID where the helix starts.
        static let initChainIDRange: Range<Int> = 19..<20
        /// Column index range of the initial residue identifier.
        static let initResIDRange: Range<Int> = 21..<25
        /// Column index range of the chainID where the helix ends.
        static let finalChainIDRange: Range<Int> = 31..<32
        /// Column index range of the final residue identifier.
        static let finalResIDRange: Range<Int> = 33..<37
    }
    
    enum SheetRecord {
        /// Column index range of the chainID where the helix starts.
        static let initChainIDRange: Range<Int> = 21..<22
        /// Column index range of the initial residue identifier.
        static let initResIDRange: Range<Int> = 22..<26
        /// Column index range of the chainID where the helix ends.
        static let finalChainIDRange: Range<Int> = 32..<33
        /// Column index range of the final residue identifier.
        static let finalResIDRange: Range<Int> = 33..<37
    }
}
