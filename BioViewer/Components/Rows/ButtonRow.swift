//
//  ButtonRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 29/11/22.
//

import SwiftUI

struct ButtonRow: View {
    
    let action: () -> Void
    let text: String
    
    var body: some View {
        Button(
            action: {
                action()
            },
            label: {
                Text(text)
            }
        )
    }
}

struct ButtonRow_Previews: PreviewProvider {
    static var previews: some View {
        ButtonRow(action: {}, text: "Test button")
    }
}
