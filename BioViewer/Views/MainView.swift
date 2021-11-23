//
//  MainView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 5/5/21.
//

import SwiftUI

struct MainView: View {

    init() {
        MetalScheduler.shared
    }

    var body: some View {
        
        // Share view between default detail in master-detail mode and the same view
        // pushed through navigation.
        let proteinView = ProteinView()
        let proteinViewModel = ProteinViewModel()
        
        NavigationView {

            // Sidebar in master-detail mode, initial view
            // in other modes
            List {
                NavigationLink(
                    destination: proteinView
                        .environmentObject(proteinViewModel),
                    label: {
                        Text(NSLocalizedString("View protein structure", comment: ""))
                })
                // TO-DO: Add missing views
                /*
                NavigationLink(
                    destination: SequenceView(),
                    label: {
                        Text(NSLocalizedString("View sequence", comment: ""))
                })
                NavigationLink(
                    destination: SettingsView(),
                    label: {
                        Text(NSLocalizedString("Settings", comment: ""))
                })
                */
            }
            .listStyle( SidebarListStyle() )
            .navigationBarHidden(false)
            .navigationTitle(Text("BioViewer"))
            
            // Initial view in master-detail mode
            proteinView.environmentObject(proteinViewModel)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
