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
    var indent: Bool = false

    var body: some View {
        HStack {
            if indent {
                Spacer()
                    .frame(width: 24)
            }
            ColorPicker(title,
                        selection: $selectedColor,
                        supportsOpacity: false)
        }
    }
}

struct ColorPickerRow_Previews: PreviewProvider {
    static var previews: some View {
        ColorPickerRow(title: NSLocalizedString("Selected color", comment: ""),
                       selectedColor: .constant(Color.black),
                       indent: false)
    }
}
