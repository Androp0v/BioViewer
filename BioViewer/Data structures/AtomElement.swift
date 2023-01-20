//
//  AtomTypeRepresentation.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 7/5/21.
//

import Foundation
import SwiftUI

enum AtomElement: UInt8, CaseIterable {
    case unknown = 0
    case hydrogen = 1
    case carbon = 6
    case nitrogen = 7
    case oxygen = 8
    case fluorine = 9
    case sodium = 11
    case phosphorus = 15
    case sulfur = 16
    case chlorine = 17
    case potassium = 19
    case calcium = 20
    case iron = 26
    case zinc = 30
    
    var name: String {
        switch self {
        case .unknown: return NSLocalizedString("Unknown", comment: "")
        case .hydrogen: return "H"
        case .carbon: return "C"
        case .nitrogen: return "N"
        case .oxygen: return "O"
        case .fluorine: return "F"
        case .sodium: return "Na"
        case .phosphorus: return "P"
        case .sulfur: return "S"
        case .chlorine: return "Cl"
        case .potassium: return "K"
        case .calcium: return "Ca"
        case .iron: return "Fe"
        case .zinc: return "Zn"
        }
    }
    
    var defaultColor: Color {
        switch self {
        case .hydrogen: return Color(red: 1.000, green: 1.000, blue: 1.000)
        case .carbon: return Color(red: 0.423, green: 0.733, blue: 0.235)
        case .nitrogen: return Color(red: 0.091, green: 0.148, blue: 0.556)
        case .oxygen: return Color(red: 1.000, green: 0.149, blue: 0.000)
        case .sulfur: return Color(red: 1.000, green: 0.780, blue: 0.349)
        default: return Color(red: 0.517, green: 0.517, blue: 0.517)
        }
    }
    
    var vanDerWaalsRadius: Float {
        switch self {
        case .unknown: return 1.0
        case .hydrogen: return 1.10
        case .carbon: return 1.50
        case .nitrogen: return 1.55
        case .oxygen: return 1.52
        case .fluorine: return 1.47
        case .sodium: return 2.27
        case .phosphorus: return 1.80
        case .sulfur: return 1.80
        case .chlorine: return 1.75
        case .potassium: return 2.80
        case .calcium: return 2.31
        case .iron: return 1.94
        case .zinc: return 1.39
        }
    }
    
    init(index: Int) {
        if let element = AtomElement(rawValue: UInt8(index)) {
            self = element
        } else {
            self = .unknown
        }
    }
    
    init(string: String) {
        switch string.uppercased() {
        case "H": self = .hydrogen
        case "C": self = .carbon
        case "N": self = .nitrogen
        case "O": self = .oxygen
        case "F": self = .fluorine
        case "NA": self = .sodium
        case "P": self = .phosphorus
        case "S": self = .sulfur
        case "Cl": self = .chlorine
        case "K": self = .potassium
        case "CA": self = .calcium
        case "FE": self = .iron
        case "ZN": self = .zinc
        default: self = .unknown
        }
    }
}
