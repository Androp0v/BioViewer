//
//  MainView.swift
//  PDB Viewer
//
//  Created by Raúl Montón Pinillos on 5/5/21.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(
                    destination: ProteinView(),
                    label: {
                        Text("View protein!")
                })
            }
            .listStyle(SidebarListStyle())
            ProteinView()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
