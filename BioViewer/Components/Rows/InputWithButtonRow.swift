//
//  InputWithButtonRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 18/12/21.
//

import SwiftUI

struct InputWithButtonRow: View {
    var body: some View {
        HStack {
            Text("Go to frame")
            TextField("Hey", text: .constant("0"), prompt: nil)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .multilineTextAlignment(.trailing)
            Button(action: {
                // TO-DO
            }, label: {
                Text("Go")
            })
                .buttonStyle(BorderedProminentButtonStyle())
        }
    }
}

struct InputWithButtonRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            InputWithButtonRow()
        }
    }
}
