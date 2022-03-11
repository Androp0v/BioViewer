//
//  ProteinSolidSpheresRadiusOptions.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 11/3/22.
//

import Foundation

enum ProteinSolidSpheresRadiusOptions: Int, CaseIterable {
    case vanDerWaals = 0
    case fixed = 1
    
    static func getPickerOptions() -> [String] {
        var optionNames = [String]()
        ProteinSolidSpheresRadiusOptions.allCases.forEach { option in
            switch option {
            case .vanDerWaals:
                optionNames.append("Van Der Waals")
            case .fixed:
                optionNames.append("Fixed")
            }
        }
        return optionNames
    }
}
