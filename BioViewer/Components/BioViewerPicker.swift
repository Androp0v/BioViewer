//
//  BioViewerPicker.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 21/1/23.
//

import SwiftUI

struct BioViewerPicker<T: PickableEnum>: View {
    
    @Binding var selection: T
    
    var body: some View {
        #if targetEnvironment(macCatalyst)
        Picker("", selection: $selection.animation()) {
            ForEach(Array(T.allCases), id: \.self) {
                Text($0.displayName)
                    .tag($0)
            }
        }
        .pickerStyle(MenuPickerStyle())
        #else
        Menu {
            Picker("", selection: $selection.animation()) {
                ForEach(Array(T.allCases), id: \.self) {
                    Text($0.displayName)
                        .tag($0)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selection.displayName)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
        }
        #endif
    }
}
