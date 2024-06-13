//
//  InfoPopoverRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 11/5/21.
//

import SwiftUI

struct InfoPopoverRow<Content: View>: View {
    
    let label: String
    let value: String
    let isDisabled: Bool
    let popoverView: Content
    @State var buttonToggle: Bool = false
    
    init(label: String, value: String, isDisabled: Bool, @ViewBuilder content: () -> Content) {
        self.label = label
        self.value = value
        self.isDisabled = isDisabled
        self.popoverView = content()
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
            Text(value)
                .foregroundColor(.secondaryLabel)
            Spacer()
            Button(
                action: {
                    buttonToggle.toggle()
                },
                label: {
                    Image(systemName: "info.circle")
                }
            )
            .foregroundColor(.secondaryLabel)
            .buttonStyle(PlainButtonStyle())
            .disabled(isDisabled)
            .popover(isPresented: $buttonToggle) {
                popoverView
            }
        }
    }
}

struct InformationRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            InfoPopoverRow(label: "Número de átomos",
                                  value: "58336",
                                  isDisabled: false,
                                  content: { FileCompositionView() })
        }
    }
}
