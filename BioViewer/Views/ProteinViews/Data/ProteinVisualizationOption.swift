//
//  ProteinVisualizationOption.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 31/12/21.
//

import Foundation

enum ProteinVisualizationOption: Int, CaseIterable {
    case solidSpheres = 0
    case ballAndStick = 1
    
    static func getPickerOptions() -> [String] {
        var optionNames = [String]()
        ProteinVisualizationOption.allCases.forEach { option in
            switch option {
            case .solidSpheres:
                optionNames.append("Space-filling spheres")
            case .ballAndStick:
                optionNames.append("Ball and stick (beta)")
            }
        }
        return optionNames
    }
}
