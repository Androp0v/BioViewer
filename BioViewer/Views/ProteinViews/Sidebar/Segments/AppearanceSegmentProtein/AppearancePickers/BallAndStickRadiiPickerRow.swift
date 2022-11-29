//
//  AtomRadiiPickerRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 11/3/22.
//

import SwiftUI

struct BallAndStickRadiiPickerRow: View {
    
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    var ballAndStickRadiusProxy: Binding<Int> {
        Binding<Int>(
            get: {
                proteinViewModel.ballAndStickRadiusOption.rawValue
            },
            set: {
                proteinViewModel.ballAndStickRadiusOption = .init(rawValue: $0) ?? .fixed
            }
        )
    }
    
    var body: some View {
        PickerRow(optionName: NSLocalizedString("Radius", comment: ""),
                  selectedOption: ballAndStickRadiusProxy,
                  pickerOptions: ProteinBallAndStickRadiusOptions.getPickerOptions())
    }
}

struct BallAndStickRadiiPickerRow_Previews: PreviewProvider {
    static var previews: some View {
        BallAndStickRadiiPickerRow()
    }
}
