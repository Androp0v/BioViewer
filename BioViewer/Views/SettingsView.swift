//
//  SettingsView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/5/21.
//

import SwiftUI

struct SettingsView: View {

    @State private var showingCoffeeView = false

    var body: some View {
        VStack(spacing: 12) {
            Text("Settings")
            Button("Buy me a coffee ☕️", action: {
                showingCoffeeView.toggle()
            })
            .sheet(isPresented: $showingCoffeeView, content: {
                BuyCoffeeView(showingCoffeeView: $showingCoffeeView)
            })
            
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
