//
//  ColorPickerRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/5/21.
//

import SwiftUI

struct ColorPickerRow: View {

    @Binding var selectedColor: Color

    var body: some View {
        HStack {
            ColorPicker("Background color:",
                        selection: $selectedColor,
                        supportsOpacity: false)
        }
    }
}

struct ColorPickerRow_Previews: PreviewProvider {
    static var previews: some View {
        ColorPickerRow(selectedColor: .constant(Color.black))
    }
}
