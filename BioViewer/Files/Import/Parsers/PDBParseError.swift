//
//  PDBParseError.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 15/1/23.
//

import Foundation

enum PDBParseError: Error {
    case unexpectedLineLength
    case missingResidueID
    case invalidResidueName
    case invalidAtomCoordinates
}
