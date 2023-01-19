//
//  SolidSpheresRadiusOptions.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 11/3/22.
//

import Foundation

enum SolidSpheresRadiusOptions: PickableEnum {
    case vanDerWaals
    case fixed
    
    var displayName: String {
        switch self {
        case .vanDerWaals:
            return NSLocalizedString("Van Der Waals", comment: "")
        case .fixed:
            return NSLocalizedString("Fixed", comment: "")
        }
    }
}
