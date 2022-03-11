//
//  ProteinSolidSpheresRadiusOptions.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 11/3/22.
//

import Foundation

enum ProteinBallAndStickRadiusOptions: Int, CaseIterable {
    case fixed = 0
    case scaledVDW = 1
    
    static func getPickerOptions() -> [String] {
        var optionNames = [String]()
        ProteinBallAndStickRadiusOptions.allCases.forEach { option in
            switch option {
            case .fixed:
                optionNames.append("Fixed")
            case .scaledVDW:
                optionNames.append("Van Der Waals")
            }
        }
        return optionNames
    }
}
