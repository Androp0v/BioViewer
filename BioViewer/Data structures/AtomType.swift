//
//  AtomTypeRepresentation.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 7/5/21.
//

import Foundation
import SwiftUI

enum AtomTypeEnum: CaseIterable {
    case carbon
    case nitrogen
    case hydrogen
    case oxygen
    case sulfur
    case others
}

struct AtomType {
    static let UNKNOWN: UInt8 = 0
    static let HYDROGEN: UInt8 = 1
    static let CARBON: UInt8 = 6
    static let NITROGEN: UInt8 = 7
    static let OXYGEN: UInt8 = 8
    static let FLUORINE: UInt8 = 9
    static let SULFUR: UInt8 = 16
    static let POTASSIUM: UInt8 = 19
    static let IRON: UInt8 = 26
}

class AtomTypeUtilities {
    
    static let atomTypeDict: [String: UInt8] =
        ["H": 1,
         "HE": 2,
         "LI": 3,
         "BE": 4,
         "B": 5,
         "C": 6,
         "N": 7,
         "O": 8,
         "F": 9,
         "NE": 10,
         "NA": 11,
         "MG": 12,
         "AL": 13,
         "SI": 14,
         "P": 15,
         "S": 16,
         "CL": 17,
         "AR": 18,
         "K": 19,
         "CA": 20,
         "SC": 21,
         "TI": 22,
         "V": 23,
         "CR": 24,
         "MN": 25,
         "FE": 26,
         "CO": 27,
         "NI": 28,
         "CU": 29,
         "ZN": 30,
         "GA": 31,
         "GE": 32,
         "AS": 33,
         "SE": 34,
         "BR": 35,
         "KR": 36,
         "I": 53]
        
    static func getAtomId(atomName: String) -> UInt8 {
        return AtomTypeUtilities.atomTypeDict[atomName.uppercased(), default: AtomType.UNKNOWN]
    }

    /// Return atom Van Der Waals size in Armstrongs based on the type
    /// - Parameter atomType: Atom type identifier, defined in AtomType.swift
    /// - Returns: Atomic radius (in Armstrongs)
    static func getAtomicVanDerWaalsRadius(atomType: UInt8) -> Float {
        
        switch atomType {
        case AtomType.CARBON:
            return 1.50
        case AtomType.HYDROGEN:
            return 1.10
        case AtomType.NITROGEN:
            return 1.55
        case AtomType.OXYGEN:
            return 1.52
        case AtomType.FLUORINE:
            return 1.47
        case AtomType.SULFUR:
            return 1.80
        case AtomType.POTASSIUM:
            return 2.80
        case AtomType.IRON:
            return 1.94
        default: return 1.0
        }
    }
    
    static func getAtomicColor(atomType: UInt8) -> Color {
        
        switch atomType {
        case AtomType.CARBON:
            return Color(.displayP3, red: 0.423, green: 0.733, blue: 0.235, opacity: 1.0)
        case AtomType.HYDROGEN:
            return Color(.displayP3, red: 1.000, green: 1.000, blue: 1.000, opacity: 1.0)
        case AtomType.NITROGEN:
            return Color(.displayP3, red: 0.091, green: 0.148, blue: 0.556, opacity: 1.0)
        case AtomType.OXYGEN:
            return Color(.displayP3, red: 1.000, green: 0.149, blue: 0.000, opacity: 1.0)
        case AtomType.FLUORINE:
            return Color(.displayP3, red: 1.000, green: 0.427, blue: 1.000, opacity: 1.0)
        case AtomType.SULFUR:
            return Color(.displayP3, red: 1.000, green: 0.780, blue: 0.349, opacity: 1.0)
        default:
            return Color(.displayP3, red: 0.517, green: 0.517, blue: 0.517, opacity: 1.0)
        }
    }
}
