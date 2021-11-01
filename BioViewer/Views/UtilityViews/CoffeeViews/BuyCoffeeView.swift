//
//  TipJarView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/5/21.
//

import SwiftUI

struct BuyCoffeeView: View {

    // Used to present the view as a sheet
    @Binding var showingCoffeeView: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Text(NSLocalizedString("Hello there! You can buy me a coffee if you want to and contribute supporting BioViewer.",
                                       comment: ""))
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                List {
                    Section(header: Text(NSLocalizedString("Coffee options: ", comment: "")),
                            footer: Text(NSLocalizedString("Thank you!", comment: "")),
                            content: {
                                CoffeeTipRow(text: NSLocalizedString("Tasty coffee pod", comment: ""),
                                           price: "$0.99")
                                CoffeeTipRow(text: NSLocalizedString("Nice bar coffee", comment: ""),
                                           price: "$1.99")
                                CoffeeTipRow(text: NSLocalizedString("Caramel Macchiato", comment: ""),
                                           price: "$4.99")
                                CoffeeTipRow(text: NSLocalizedString("Caramel Macchiato + biscuits", comment: ""),
                                           price: "$9.99")
                            })
                    Section(header: Text(NSLocalizedString("Purchased coffees:", comment: "")),
                            content: {
                                CoffeeRow()
                                    .listRowInsets(EdgeInsets())
                            })
                }
                .listStyle(InsetGroupedListStyle())
            }
            .background(Color(UIColor.secondarySystemBackground))
            .navigationBarTitle(NSLocalizedString("Buy me a coffee ☕️", comment: ""),
                                displayMode: .inline)
            .navigationBarItems(leading: Button(NSLocalizedString("Close", comment: ""), action: {
                showingCoffeeView.toggle()
            }))
        }
        .edgesIgnoringSafeArea(.all)

    }
}

struct TipJar_Previews: PreviewProvider {
    static var previews: some View {
        BuyCoffeeView(showingCoffeeView: .constant(true))
    }
}
