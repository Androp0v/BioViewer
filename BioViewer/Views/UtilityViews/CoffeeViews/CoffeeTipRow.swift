//
//  TipRowView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/5/21.
//

import SwiftUI

struct CoffeeTipRow: View {

    var text: String
    var price: String

    var body: some View {
        HStack {
            Text(text)
            Spacer()
            Button(price, action: {
                // TO-DO: Handle in-app purchase
            })
            .foregroundColor(.accentColor)
            // PlainButtonStyle() makes the list row not selectable,
            // as we want.
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct TipRowView_Previews: PreviewProvider {
    static var previews: some View {
        CoffeeTipRow(text: "Small tip", price: "$0.99")
    }
}
