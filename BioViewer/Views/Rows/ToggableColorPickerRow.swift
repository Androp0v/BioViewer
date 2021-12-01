//
//  ToggableColorPickerRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 29/11/21.
//

import SwiftUI

struct ToggableColorPickerRow: View {
    
    var title: String
    @Binding var selectedColor: Color
    var indent: Bool = false
    @State var show: Bool = true
    
    var body: some View {
        HStack {
            ColorPickerRow(title: title, selectedColor: $selectedColor, indent: indent)
            Button(action: {
                show.toggle()
            },
                   label: {
                ZStack {
                    Image(systemName: show ? "eye" : "eye.slash")
                        .contentShape(Rectangle())
                        .frame(width: 16, height: 16)
                }
            })
            #if targetEnvironment(macCatalyst)
                .foregroundColor(Color(uiColor: .systemGray))
            #endif
                .contentShape(Rectangle())
        }
    }
}

struct ToggableColorPickerRow_Previews: PreviewProvider {
    static var previews: some View {
        ToggableColorPickerRow(title: "Toggable picker", selectedColor: .constant(.red))
    }
}
