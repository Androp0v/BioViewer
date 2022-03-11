//
//  AtomRadiiPickerRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 11/3/22.
//

import SwiftUI

struct AtomRadiiPickerRow: View {
    
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    var solidSpheresRadiusProxy: Binding<Int> {
        Binding<Int>(
            get: {
                proteinViewModel.solidSpheresRadiusOption.rawValue
            },
            set: {
                proteinViewModel.solidSpheresRadiusOption = .init(rawValue: $0) ?? .vanDerWaals
            }
        )
    }
    
    var body: some View {
        PickerRow(optionName: NSLocalizedString("View as", comment: ""),
                  selectedOption: solidSpheresRadiusProxy,
                  pickerOptions: ProteinSolidSpheresRadiusOptions.getPickerOptions())
    }
}

struct AtomRadiiPickerRow_Previews: PreviewProvider {
    static var previews: some View {
        AtomRadiiPickerRow()
    }
}
