//
//  MainView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 5/5/21.
//

import SwiftUI

struct MainView: View {
    
    @State var isPresentingNews = false
            
    init() {
        
        // Custom segmented controls in the app
        #if targetEnvironment(macCatalyst)
        // selectedSegmentTintColor does not work on macCatalyst :(
        #else
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(Color.accentColor)
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.foregroundColor: UIColor.white],
            for: .selected
        )
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.foregroundColor: UIColor(Color.accentColor)],
            for: .normal
        )
        #endif
    }

    var body: some View {
        
        let proteinViewModel = ProteinViewModel()
        
        NavigationView {
            ProteinView()
                .environmentObject(proteinViewModel)
            
                .sheet(isPresented: $isPresentingNews, onDismiss: {
                    AppState.shared.userHasSeenWhatsNew()
                }, content: {
                    WhatsNewView()
                })
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            if AppState.shared.shouldShowWhatsNew() {
                isPresentingNews = true
            }
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
