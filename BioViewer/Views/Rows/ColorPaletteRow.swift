//
//  ColorPaletteRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/12/21.
//

import SwiftUI

struct ColorPaletteRow: View {
    
    var indent: Bool = false
    @State var showPalettePicker: Bool = false
    let colorPalette: ColorPalette
    
    var body: some View {
        HStack {
            
            if indent {
                Spacer()
                    .frame(width: 24)
            }
            Text(NSLocalizedString("Color palette", comment: ""))
            Spacer()
            Button(action: {
                showPalettePicker.toggle()
            }, label: {
                ColorPaletteView(colorPalette: colorPalette)
                    .popover(isPresented: $showPalettePicker) {
                        ColorPalettePopover()
                    }
            })
                .buttonStyle(PlainButtonStyle())
        }
    }
}

struct ColorPaletteRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ColorPaletteRow(colorPalette: ColorPalette(.default))
        }
    }
}
