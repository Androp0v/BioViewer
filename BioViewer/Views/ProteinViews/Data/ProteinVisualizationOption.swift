//
//  ProteinVisualizationOption.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 31/12/21.
//

import Foundation

enum ProteinVisualizationOption: Int, CaseIterable {
    case none = 0
    case solidSpheres = 1
    case ballAndStick = 2
    
    static func getPickerOptions() -> [String] {
        var optionNames = [String]()
        ProteinVisualizationOption.allCases.forEach { option in
            switch option {
            case .none:
                optionNames.append("None")
            case .solidSpheres:
                optionNames.append("Space-filling spheres")
            case .ballAndStick:
                optionNames.append("Ball and stick (beta)")
            }
        }
        return optionNames
    }
}
