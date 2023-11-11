//
//  ColorPaletteView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/12/21.
//

import SwiftUI

struct ColorPaletteView: View {
    
    let colorPalette: ColorPalette
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    colorPalette.color0
                    colorPalette.color1
                    colorPalette.color2
                }
                HStack(spacing: 2) {
                    colorPalette.color3
                    colorPalette.color4
                    colorPalette.color5
                }
            }
            .padding(4)
        }
        .frame(width: 88, height: 36)
        .mask(RoundedRectangle(cornerRadius: 4)
                .padding(4))
        .background(RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(uiColor: .separator),
                            style: StrokeStyle(lineWidth: 1))
                    .background(RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(uiColor: .tertiarySystemFill))))
    }
}

struct ColorPaletteView_Previews: PreviewProvider {
    static var previews: some View {
        ColorPaletteView(colorPalette: ColorPalette(.default))
    }
}
