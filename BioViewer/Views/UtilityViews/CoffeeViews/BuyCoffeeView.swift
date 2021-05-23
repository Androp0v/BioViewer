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
                Text("Hello there! You can buy me a coffee if you want to, to contribute supporting BioViewer.")
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                List {
                    Section(header: Text("Coffe options:"),
                            footer: Text("Thank you!"),
                            content: {
                                CoffeeTipRow(text: "Tasty coffee pod",
                                           price: "$0.99")
                                CoffeeTipRow(text: "Nice bar coffee",
                                           price: "$1.99")
                                CoffeeTipRow(text: "Caramel Macchiato",
                                           price: "$4.99")
                                CoffeeTipRow(text: "Caramel Macchiato + biscuits",
                                           price: "$9.99")
                            })
                    Section(header: Text("Purchased coffees:"),
                            content: {
                                CoffeeRow()
                                    .listRowInsets(EdgeInsets())
                            })
                }
                .listStyle(InsetGroupedListStyle())
            }
            .background(Color(UIColor.secondarySystemBackground))
            .navigationBarTitle("Buy me a coffee ☕️",
                                displayMode: .inline)
            .navigationBarItems(leading: Button("Close", action: {
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
