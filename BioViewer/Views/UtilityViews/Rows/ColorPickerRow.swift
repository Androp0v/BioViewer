//
//  ColorPickerRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/5/21.
//

import SwiftUI

struct ColorPickerRow: View {

    @State var title: String
    @Binding var selectedColor: Color

    var body: some View {
        HStack {
            ColorPicker(title,
                        selection: $selectedColor,
                        supportsOpacity: false)
        }
    }
}

struct ColorPickerRow_Previews: PreviewProvider {
    static var previews: some View {
        ColorPickerRow(title: "Selected color", selectedColor: .constant(Color.black))
    }
}
