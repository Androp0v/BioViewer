//
//  ColorPalettePopoverRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/12/21.
//

import SwiftUI

struct ColorPalettePopoverRow: View {
    
    @Binding var selectedOption: Int
    let colorPalette: ColorPalette
    
    let paletteName: String
    let optionIndex: Int
    
    private enum Constants {
        #if targetEnvironment(macCatalyst)
        static let radioButtonSize: CGFloat = 16
        #else
        static let radioButtonSize: CGFloat = 20
        #endif
    }
    
    var body: some View {
        Button(action: {
            selectedOption = optionIndex
        }, label: {
            HStack {
                Image(systemName: selectedOption == optionIndex ? "checkmark.circle" : "circle")
                    .padding(4)
                    .font(Font.system(size: Constants.radioButtonSize, weight: .medium))
                    .foregroundColor(.accentColor)
                Text(paletteName)
                    .foregroundColor(.accentColor)
                Spacer()
                ColorPaletteView(colorPalette: colorPalette)
            }
            .contentShape(Rectangle())
        })
            .buttonStyle(PlainButtonStyle())
    }
}

struct ColorPalettePopoverRow_Previews: PreviewProvider {
    static var previews: some View {
        ColorPalettePopoverRow(selectedOption: .constant(0),
                               colorPalette: ColorPalette(.default),
                               paletteName: "TestPalette",
                               optionIndex: 0)
    }
}
