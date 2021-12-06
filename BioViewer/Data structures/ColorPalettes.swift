//
//  ColorPalettes.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/12/21.
//

import Foundation
import SwiftUI

enum ColorPaletteType {
    case `default`
    case bioViewer
    case custom
}

struct ColorPalette {
    let color0: Color
    let color1: Color
    let color2: Color
    let color3: Color
    let color4: Color
    let color5: Color
    
    init(_ colorPaletteType: ColorPaletteType) {
        // TO-DO:
        switch colorPaletteType {
        case .bioViewer:
            color0 = .purple
            color1 = .purple
            color2 = .purple
            color3 = .purple
            color4 = .purple
            color5 = .purple
        default:
            color0 = .green
            color1 = .gray
            color2 = .blue
            color3 = .red
            color4 = .orange
            color5 = .gray
        }
    }
}
