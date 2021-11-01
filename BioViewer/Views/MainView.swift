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
        NavigationView {

            // Sidebar in master-detail mode, initial view
            // in other modes
            List {
                NavigationLink(
                    destination: ProteinView()
                        .environmentObject(ProteinViewModel()),
                    label: {
                        Text(NSLocalizedString("View protein structure", comment: ""))
                })
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
            }
            .listStyle( SidebarListStyle() )
            .navigationBarHidden(false)
            .navigationTitle(Text("BioViewer"))
            
            // Initial view in master-detail mode
            ProteinView().environmentObject(ProteinViewModel())
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
