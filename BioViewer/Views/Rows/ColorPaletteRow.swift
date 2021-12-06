//
//  ColorPaletteRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/12/21.
//

import SwiftUI

struct ColorPaletteRow: View {
    
    var indent: Bool = false
    
    var body: some View {
        HStack {
            
            if indent {
                Spacer()
                    .frame(width: 24)
            }
            
            Text(NSLocalizedString("Color palette", comment: ""))
            
            Spacer()
            Button(action: {
                // TO-DO
            }, label: {
                VStack(spacing: 0) {
                    VStack(spacing: 2) {
                        HStack(spacing: 2) {
                            Color.green
                            Color.gray
                            Color.blue
                        }
                        HStack(spacing: 2) {
                            Color.red
                            Color.orange
                            Color.gray
                        }
                    }
                    .padding(4)
                }
                #if targetEnvironment(macCatalyst)
                .frame(width: 88, height: 28)
                .background(Rectangle()
                            .stroke(Color(uiColor: .darkGray),
                                    style: StrokeStyle(lineWidth: 1))
                            .background(Rectangle()
                                            .fill(Color(uiColor: .tertiarySystemFill))))
                #else
                .frame(width: 88, height: 36)
                .mask(RoundedRectangle(cornerRadius: 4)
                        .padding(4))
                .background(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(uiColor: .separator),
                                    style: StrokeStyle(lineWidth: 1))
                            .background(Rectangle()
                                            .fill(Color(uiColor: .tertiarySystemFill))))
                #endif
            })
                .buttonStyle(PlainButtonStyle())
        }
    }
}

struct ColorPaletteRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ColorPaletteRow()
        }
    }
}
