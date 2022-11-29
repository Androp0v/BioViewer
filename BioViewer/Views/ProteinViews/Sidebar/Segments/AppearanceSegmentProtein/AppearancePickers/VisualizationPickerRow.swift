//
//  VisualizationPickerRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 2/1/22.
//

import SwiftUI

struct VisualizationPickerRow: View {
    
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    var visualizationProxy: Binding<Int> {
        Binding<Int>(
            get: {
                proteinViewModel.visualization.rawValue
            },
            set: {
                proteinViewModel.visualization = .init(rawValue: $0) ?? .ballAndStick
            }
        )
    }
    
    var body: some View {
        PickerRow(
            optionName: NSLocalizedString("View as", comment: ""),
            selectedOption: visualizationProxy,
            pickerOptions: ProteinVisualizationOption.getPickerOptions()
        )
    }
}

struct VisualizationPickerRow_Previews: PreviewProvider {
    static var previews: some View {
        VisualizationPickerRow()
    }
}
