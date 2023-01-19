//
//  PickerRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 19/1/23.
//

import SwiftUI

protocol PickableEnum: CaseIterable, Hashable {
    var displayName: String { get }
}

struct PickerRow<T: PickableEnum>: View {

    let optionName: String
    @Binding var selection: T
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init(optionName: String, selection: Binding<T>) {
        self.optionName = optionName
        self._selection = selection
    }
    
    var body: some View {
        #if targetEnvironment(macCatalyst)
        HStack(spacing: .zero) {
            Text(optionName)
            Picker("", selection: $selection.animation()) {
                ForEach(Array(T.allCases), id: \.self) {
                    Text($0.displayName)
                        .tag($0)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: .infinity)
        }
        #else
        HStack {
            Text(optionName + ":")
            Spacer()
            Menu {
                Picker("", selection: $selection.animation()) {
                    ForEach(Array(T.allCases), id: \.self) {
                        Text($0.displayName)
                            .tag($0)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(pickerOptions[selectedOption - startIndex])
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
        }
        #endif
    }
}
