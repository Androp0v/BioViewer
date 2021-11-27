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
        // Open documents in view from other apps
        .onOpenURL { fileURL in
            // FIXME: Refactor all import paths to avoid code repetition
            print(fileURL)
            guard let proteinData = try? Data(contentsOf: fileURL) else {
                return
            }
            proteinViewModel.statusUpdate(statusText: NSLocalizedString("Importing file", comment: ""))
            let rawText = String(decoding: proteinData, as: UTF8.self)
            proteinViewModel.statusUpdate(statusText: NSLocalizedString("Importing file", comment: ""))
            do {
                var protein = try FileParser().parseTextFile(rawText: rawText,
                                                             fileExtension: "pdb",
                                                             fileInfo: nil,
                                                             proteinViewModel: proteinViewModel)
                proteinViewModel.dataSource.addProteinToDataSource(protein: &protein, addToScene: true)
            } catch let error as ImportError {
                proteinViewModel.statusFinished(importError: error)
            } catch {
                proteinViewModel.statusFinished(importError: ImportError.unknownError)
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
