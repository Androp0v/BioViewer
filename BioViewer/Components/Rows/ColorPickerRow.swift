//
//  ColorPickerRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/5/21.
//

import SwiftUI

struct ColorPickerRow: View {

    var title: String
    @Binding var selectedColor: Color

    var body: some View {
        HStack {
            #if targetEnvironment(macCatalyst)
            Text(title)
            Spacer()
            ColorPicker(
                "",
                selection: $selectedColor,
                supportsOpacity: false
            )
                .frame(width: 96)
            #else
            ColorPicker(
                title,
                selection: $selectedColor,
                supportsOpacity: false
            )
            #endif
        }
    }
}

struct ColorPickerRow_Previews: PreviewProvider {
    static var previews: some View {
        ColorPickerRow(title: NSLocalizedString("Selected color", comment: ""),
                       selectedColor: .constant(Color.black))
    }
}
