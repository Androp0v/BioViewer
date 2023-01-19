//
//  ProteinVisualizationOption.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 31/12/21.
//

import Foundation

enum ProteinVisualizationOption: PickableEnum {
    case solidSpheres
    case ballAndStick
    
    var displayName: String {
        switch self {
        case .solidSpheres:
            return NSLocalizedString("Space-filling spheres", comment: "")
        case .ballAndStick:
            return NSLocalizedString("Ball and stick (beta)", comment: "")
        }
    }
}
