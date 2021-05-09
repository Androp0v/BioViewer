//
//  AtomTypeRepresentation.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 7/5/21.
//

import Foundation

struct AtomType {

    static let CARBON = 0
    static let NITROGEN = 1
    static let OXYGEN = 2

    static let UNKNOWN = Int.max
}

func getAtomId(atomName: String) -> Int {
    if atomName.first == "C" { return AtomType.CARBON }
    if atomName.first == "N" { return AtomType.NITROGEN }
    if atomName.first == "O" { return AtomType.OXYGEN }
    return AtomType.UNKNOWN
}

/// Return atom size in armstrongs based on the type
/// - Parameter atomType: Atom type identifier, defined in AtomType.swift
/// - Returns: Atomic radius (in armstrongs)
func getAtomicRadius(atomType: Int) -> Float {
    switch atomType {
    case AtomType.CARBON: return 0.67
    case AtomType.NITROGEN: return 0.56
    case AtomType.OXYGEN: return 0.48
    default: return 1.0
    }
}
