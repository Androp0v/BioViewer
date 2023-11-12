//
//  SecondaryStructure.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 5/3/23.
//

import Foundation
import SwiftUI

public enum SecondaryStructure: UInt8, CaseIterable, Sendable {
    case helix
    case sheet
    case loop
    case nonChain
    
    public var name: String {
        switch self {
        case .helix:
            return NSLocalizedString("Helix", comment: "")
        case .sheet:
            return NSLocalizedString("Sheet", comment: "")
        case .loop:
            return NSLocalizedString("Loop", comment: "")
        case .nonChain:
            return NSLocalizedString("Non-chain", comment: "")
        }
    }
    
    public var defaultColor: Color {
        switch self {
        case .helix:
            return Color(.displayP3, red: 0.423, green: 0.733, blue: 0.235, opacity: 1)
        case .sheet:
            return Color(.displayP3, red: 0.000, green: 0.590, blue: 1.000, opacity: 1)
        case .loop:
            return Color(.displayP3, red: 0.500, green: 0.500, blue: 0.500, opacity: 1)
        case .nonChain:
            return Color(.displayP3, red: 0.750, green: 0.750, blue: 0.750, opacity: 1)
        }
    }
}
