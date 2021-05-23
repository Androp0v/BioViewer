//
//  TipRowView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/5/21.
//

import SwiftUI

struct CoffeeRow: View {

    @State var text: String
    @State var price: String

    var body: some View {
        HStack {
            Text(text)
            Spacer()
            Button(price, action: {
                // TO-DO: Handle in-app purchase
            })
            .foregroundColor(.blue)
            // PlainButtonStyle() makes the list row not selectable,
            // as we want.
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct TipRowView_Previews: PreviewProvider {
    static var previews: some View {
        CoffeeRow(text: "Small tip", price: "$0.99")
    }
}
