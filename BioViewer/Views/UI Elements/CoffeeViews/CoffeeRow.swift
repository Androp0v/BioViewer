//
//  CoffeeRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 24/5/21.
//

import SwiftUI

struct CoffeeRow: View {
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Image("PlaceholderCoffee")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100, alignment: .center)
                Text("Bought on 12/07/2021")
                    .frame(width: 100, height: 32)
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            Spacer()
            VStack {
                Image("PlaceholderCoffee")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100, alignment: .center)
                Text("Bought on 12/07/2021")
                    .frame(width: 100, height: 32)
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            Spacer()
            VStack {
                Image("PlaceholderCoffee")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100, alignment: .center)
                Text("Bought on 12/07/2021")
                    .frame(width: 100, height: 32)
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            Spacer()
        }
        .padding(8)
    }
}

struct CoffeeRow_Previews: PreviewProvider {
    static var previews: some View {
        CoffeeRow()
            .previewLayout(.sizeThatFits)
    }
}
