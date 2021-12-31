//
//  AtomTypeRepresentation.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 7/5/21.
//

import Foundation

enum AtomTypeEnum: CaseIterable {
    case carbon
    case nitrogen
    case hydrogen
    case oxygen
    case sulfur
    case others
}

struct AtomType {
    static let CARBON: UInt8 = 0
    static let HYDROGEN: UInt8 = 1
    static let NITROGEN: UInt8 = 2
    static let OXYGEN: UInt8 = 3
    static let SULFUR: UInt8 = 4

    static let UNKNOWN: UInt8 = 5
}

func getAtomId(atomName: String) -> UInt8 {
    // Look-up atom name and match it to internally used identifier
    if atomName.first == "C" { return AtomType.CARBON }
    if atomName.first == "H" { return AtomType.HYDROGEN }
    if atomName.first == "N" { return AtomType.NITROGEN }
    if atomName.first == "O" { return AtomType.OXYGEN }
    if atomName.first == "S" { return AtomType.SULFUR }
    return AtomType.UNKNOWN
}

/// Return atom size in armstrongs based on the type
/// - Parameter atomType: Atom type identifier, defined in AtomType.swift
/// - Returns: Atomic radius (in armstrongs)
func getAtomicRadius(atomType: UInt8) -> Float {
    switch atomType {
    case AtomType.CARBON: return 1.70 // 0.67
    case AtomType.NITROGEN: return 1.55 // 0.56
    case AtomType.OXYGEN: return 1.52 // 0.48
    case AtomType.SULFUR: return 1.80 // 0.88
    case AtomType.HYDROGEN: return 1.10 // 0.53
    default: return 1.0
    }
}
