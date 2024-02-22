//
//  ColorPaletteRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/12/21.
//

import SwiftUI

struct ColorPaletteRow: View {
    
    @State var showPalettePicker: Bool = false
    let colorPalette: ColorPalette
    
    var body: some View {
        HStack {
            Text(NSLocalizedString("Color palette", comment: ""))
            Spacer()
            Button(
                action: {
                    showPalettePicker.toggle()
                }, label: {
                    ColorPaletteView(colorPalette: colorPalette)
                        .popover(isPresented: $showPalettePicker) {
                            ColorPalettePopover()
                        }
                }
            )
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
    }
}

struct ColorPaletteRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ColorPaletteRow(colorPalette: ColorPalette(.default))
        }
    }
}
