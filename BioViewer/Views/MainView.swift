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
    @State var colorViewModel = ProteinColorViewModel()
    @State var visualizationViewModel = ProteinVisualizationViewModel()
    @State var shadowsViewModel = ProteinShadowsViewModel()
    @State var graphicsSettings = ProteinGraphicsSettings()
    @State var statusViewModel = StatusViewModel()
    @State var isPresentingNews = false
            
    init() {}

    var body: some View {
        
        NavigationStack {
            ProteinView()
                .environmentObject(proteinViewModel)
                .environmentObject(proteinDataSource)
                .environment(proteinViewModel.renderer)
                .environment(colorViewModel)
                .environment(visualizationViewModel)
                .environment(shadowsViewModel)
                .environment(graphicsSettings)
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
        #if os(iOS)
        .navigationViewStyle(StackNavigationViewStyle())
        #endif
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
