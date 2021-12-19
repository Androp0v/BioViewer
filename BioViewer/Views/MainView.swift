//
//  MainView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 5/5/21.
//

import SwiftUI

struct MainView: View {
    
    init() {
        
        // Custom segmented controls in the app
        #if targetEnvironment(macCatalyst)
        // selectedSegmentTintColor does not work on macCatalyst :(
        #else
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(Color.accentColor)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white],
                                                               for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor(Color.accentColor)],
                                                               for: .normal)
        #endif
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
        // Open documents in view from other apps
        .onOpenURL { fileURL in
            try? FileImporter.importFromFileURL(fileURL: fileURL,
                                                proteinViewModel: proteinViewModel,
                                                fileInfo: nil)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
