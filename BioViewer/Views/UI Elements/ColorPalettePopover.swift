//
//  ColorPalettePopover.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/12/21.
//

import SwiftUI

struct ColorPalettePopover: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.dismiss) var dismiss
    
    struct ColorPalettePopoverContent: View {
        
        @State var paletteSelection: Int = 0
        @Environment(\.horizontalSizeClass) var horizontalSizeClass
        
        var body: some View {
            // TO-DO: Use native Radio Button on macOS
            
            VStack {
                ColorPalettePopoverRow(selectedOption: $paletteSelection,
                                       colorPalette: ColorPalette(.default),
                                       paletteName: NSLocalizedString("Default", comment: ""),
                                       optionIndex: 0)
                Divider()
                ColorPalettePopoverRow(selectedOption: $paletteSelection,
                                       colorPalette: ColorPalette(.bioViewer),
                                       paletteName: NSLocalizedString("BioViewer", comment: ""),
                                       optionIndex: 1)
                Divider()
                ColorPalettePopoverRow(selectedOption: $paletteSelection,
                                       colorPalette: ColorPalette(.custom),
                                       paletteName: NSLocalizedString("Custom", comment: ""),
                                       optionIndex: 2)
                    .disabled(true)
                if horizontalSizeClass == .compact {
                    Spacer()
                }
            }
            .padding()
        }
    }
    
    var body: some View {
        
        if horizontalSizeClass == .compact {
            NavigationView {
                ColorPalettePopoverContent()
                    .navigationTitle(NSLocalizedString("Select a palette", comment: ""))
                    #if os(iOS)
                    .navigationBarItems(leading:
                        Button(action: {
                            dismiss()
                        }, label: {
                            Text(NSLocalizedString("Close", comment: ""))
                        })
                    )
                    #endif
            }
        } else {
            ColorPalettePopoverContent()
        }
    }
}

struct ColorPalettePopover_Previews: PreviewProvider {
    static var previews: some View {
        ColorPalettePopover()
    }
}
