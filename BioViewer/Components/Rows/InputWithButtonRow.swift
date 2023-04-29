//
//  InputWithButtonRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 18/12/21.
//

import SwiftUI

struct InputWithButtonRow: View {
    
    let title: String
    @Binding var value: Float
    let buttonTitle: String
    let action: () -> Void
    let formatter: NumberFormatter
    
    var body: some View {
        HStack {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
            TextField(title, value: $value, formatter: formatter)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: 48)
                .multilineTextAlignment(.trailing)
            Button(action: {
                action()
            }, label: {
                Text(buttonTitle)
            })
                .buttonStyle(BorderedProminentButtonStyle())
        }
    }
}

struct InputWithButtonRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            InputWithButtonRow(title: "Go to frame", value: .constant(256), buttonTitle: "Go", action: {}, formatter: NumberFormatter())
        }
    }
}
