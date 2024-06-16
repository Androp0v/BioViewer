//
//  MainView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 5/5/21.
//

import SwiftUI

struct MainView: View {
    
    @State var proteinViewModel: ProteinViewModel
    @State var colorViewModel: ProteinColorViewModel
    @State var visualizationViewModel: ProteinVisualizationViewModel
    @State var statusViewModel: StatusViewModel
    
    @State var shadowsViewModel = ProteinShadowsViewModel()
    @State var graphicsSettings = ProteinGraphicsSettings()
    @State var selectionModel = SelectionModel()
    @State var isPresentingNews = false
            
    init() {
        let proteinViewModel = ProteinViewModel()
        self._proteinViewModel = State(initialValue: proteinViewModel)
        self._colorViewModel = State(initialValue: proteinViewModel.colorViewModel)
        self._visualizationViewModel = State(initialValue: proteinViewModel.visualizationViewModel)
        self._statusViewModel = State(initialValue: proteinViewModel.statusViewModel)
    }

    var body: some View {
        
        NavigationStack {
            ProteinView(proteinViewModel: proteinViewModel, renderer: proteinViewModel.renderer)
                .environmentObject(proteinViewModel.dataSource)
                .environment(colorViewModel)
                .environment(visualizationViewModel)
                .environment(shadowsViewModel)
                .environment(graphicsSettings)
                .environment(statusViewModel)
                .environment(selectionModel)
                .onAppear {
                    shadowsViewModel.proteinViewModel = proteinViewModel
                    graphicsSettings.proteinViewModel = proteinViewModel
                }
                .sheet(
                    isPresented: $isPresentingNews,
                    onDismiss: {
                        AppState.shared.userHasSeenWhatsNew()
                    },
                    content: {
                        WhatsNewView()
                    }
                )
        }
        #if os(iOS)
        .navigationViewStyle(StackNavigationViewStyle())
        #endif
        .onAppear {
            Task(priority: .userInitiated) {
                if await AppState.shared.shouldShowWhatsNew() {
                    isPresentingNews = true
                }
            }
        }
        // Open documents in view from other apps
        .onOpenURL { fileURL in
            Task {
                try? await FileImporter.importFromFileURL(
                    fileURL: fileURL,
                    proteinDataSource: proteinViewModel.dataSource,
                    statusViewModel: proteinViewModel.statusViewModel,
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
