//
//  PickerRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 19/1/23.
//

import SwiftUI

protocol PickableEnum: CaseIterable, Hashable {
    var displayName: String { get }
}

struct PickerRow<T: PickableEnum>: View {

    let optionName: String
    @Binding var selection: T
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init(optionName: String, selection: Binding<T>) {
        self.optionName = optionName
        self._selection = selection
    }
    
    var body: some View {
        #if targetEnvironment(macCatalyst)
        HStack(spacing: .zero) {
            Text(optionName)
            BioViewerPicker(selection: $selection)
        }
        #else
        HStack {
            Text(optionName + ":")
            Spacer()
            BioViewerPicker(selection: $selection)
        }
        #endif
    }
}
