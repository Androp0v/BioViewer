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

            // Sidebar in master-detail mode, initial view
            // in other modes
            List {
                NavigationLink(
                    destination: ProteinView(),
                    label: {
                        Text("View protein structure")
                })
                NavigationLink(
                    destination: SequenceView(),
                    label: {
                        Text("View sequence")
                })
            }
            .listStyle( SidebarListStyle() )
            .navigationBarHidden(false)
            .navigationTitle(Text("Protein View"))
            // Initial view in master-detail mode
            ProteinView()
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
