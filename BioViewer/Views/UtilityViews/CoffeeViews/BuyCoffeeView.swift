//
//  TipJarView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/5/21.
//

import SwiftUI

struct BuyCoffeeView: View {

    @Binding var showingCoffeeView: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Text("Hello there! You can buy me a coffee if you want to, to contribute supporting BioViewer.")
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                List {
                    Section(header: Text("Coffe options:")
                                .padding(.horizontal),
                            footer: Text("Thank you!")
                                .padding(.horizontal),
                            content:{
                                CoffeeRow(text: "Tasty coffee pod",
                                           price: "$0.99")
                                CoffeeRow(text: "Nice caffeteria coffee",
                                           price: "$1.99")
                                CoffeeRow(text: "Caramel Macchiato, Grande",
                                           price: "$4.99")
                                CoffeeRow(text: "Probably too expensive to be a coffee",
                                           price: "$9.99")
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
