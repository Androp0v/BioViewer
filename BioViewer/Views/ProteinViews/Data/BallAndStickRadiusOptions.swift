//
//  SolidSpheresRadiusOptions.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 11/3/22.
//

import Foundation

enum BallAndStickRadiusOptions: PickableEnum {
    case fixed
    case scaledVDW
    
    var displayName: String {
        switch self {
        case .fixed:
            return NSLocalizedString("Fixed", comment: "")
        case .scaledVDW:
            return NSLocalizedString("Van Der Waals", comment: "")
        }
    }
}
