//
//  MainView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 5/5/21.
//

import SwiftUI

struct MainView: View {
    
    @StateObject var proteinViewModel = ProteinViewModel()
    @StateObject var proteinDataSource = ProteinDataSource()
    @StateObject var colorViewModel = ProteinColorViewModel()
    @StateObject var visualizationViewModel = ProteinVisualizationViewModel()
    @StateObject var shadowsViewModel = ProteinShadowsViewModel()
    @StateObject var graphicsSettings = ProteinGraphicsSettings()
    @State var statusViewModel = StatusViewModel()
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
        
        NavigationStack {
            ProteinView()
                .environmentObject(proteinViewModel)
                .environmentObject(proteinDataSource)
                .environmentObject(colorViewModel)
                .environmentObject(visualizationViewModel)
                .environmentObject(shadowsViewModel)
                .environmentObject(graphicsSettings)
                .environment(statusViewModel)
                .onAppear {
                    
                    proteinDataSource.proteinViewModel = proteinViewModel
                    proteinViewModel.dataSource = proteinDataSource
                    
                    colorViewModel.proteinViewModel = proteinViewModel
                    proteinViewModel.colorViewModel = colorViewModel
                    
                    visualizationViewModel.proteinViewModel = proteinViewModel
                    proteinViewModel.visualizationViewModel = visualizationViewModel
                    
                    shadowsViewModel.proteinViewModel = proteinViewModel
                    
                    graphicsSettings.proteinViewModel = proteinViewModel
                    
                    statusViewModel.proteinViewModel = proteinViewModel
                    proteinViewModel.statusViewModel = statusViewModel
                }
            
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
            Task {
                try? await FileImporter.importFromFileURL(
                    fileURL: fileURL,
                    proteinDataSource: proteinDataSource,
                    statusViewModel: statusViewModel,
                    fileInfo: nil
                )
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
