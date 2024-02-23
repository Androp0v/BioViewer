//
//  ProteinImportView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 25/5/21.
//

import SwiftUI

struct ProteinImportView: View {

    @EnvironmentObject var proteinDataSource: ProteinDataSource
    @Environment(StatusViewModel.self) var statusViewModel: StatusViewModel
    @State var willLoadProtein: Bool = false
    @State var showFileImporter: Bool = false
    @State var showRCSBImportSheet: Bool = false

    public enum ImportAction {
        case importFile
        case downloadFromRCSB
        case downloadFromURL
        case sampleProtein
    }
    
    var body: some View {
        ZStack {
            
            // Background
            Color.black
            
            // Import actions
            VStack(spacing: 32) {
                // TO-DO: Enable missing row
                ImportRowView(
                    title: NSLocalizedString("Import files", comment: ""),
                    imageName: "square.and.arrow.down",
                    action: ImportAction.importFile,
                    parent: self
                )
                .fileImporter(
                    isPresented: $showFileImporter,
                    allowedContentTypes: [.pdbFiles, .xyzFiles],
                    onCompletion: { result in
                        do {
                            loadFile(at: try result.get())
                        } catch {
                            failedToLoad()
                        }
                    }
                )
                ImportRowView(
                    title: NSLocalizedString("Download from RCSB", comment: ""),
                    imageName: "arrow.down.doc",
                    action: ImportAction.downloadFromRCSB,
                    parent: self
                )
                /*
                ImportRowView(title: NSLocalizedString("Download from URL", comment: ""),
                              imageName: "link",
                              action: ImportAction.downloadFromURL,
                              parent: self)
                */
                ImportRowView(
                    title: NSLocalizedString("Sample protein", comment: ""),
                    imageName: "puzzlepiece",
                    action: ImportAction.sampleProtein,
                    parent: self
                )
            }
            .frame(alignment: .leading)
            
            // Supported files
            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Supported files:")
                        .foregroundColor(.gray)
                    Divider()
                        .background(Color.gray)
                    HStack {
                        Text(".pdb")
                            .foregroundColor(.gray)
                            .bold()
                        Text(".cif")
                            .foregroundColor(.gray)
                            .bold()
                        Text(".xyz")
                            .foregroundColor(.gray)
                            .bold()
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showRCSBImportSheet, onDismiss: nil, content: {
            RCSBImportView(rcsbShowSheet: $showRCSBImportSheet)
        })
    }

    // MARK: - Import action
    
    public func launchImportAction(action: ImportAction) {

        // Avoid user tapping a load action twice before the first one is loaded
        guard willLoadProtein == false else { return }

        switch action {
        case .importFile:
            showFileImporter.toggle()
            
        case .downloadFromRCSB:
            // Download from RCSB
            showRCSBImportSheet.toggle()
            
        case .downloadFromURL:
            // Download from URL
            // TO-DO: download from URL
            fatalError()
            
        case .sampleProtein:
            // Import sample protein
            // Disable import actions while processing this action
            willLoadProtein = true
            // Dispatch on background queue, file loading can be slow
            Task(priority: .userInitiated) {
                guard let fileURL = Bundle.main.url(forResource: "3JBT", withExtension: "pdb") else {
                    failedToLoad()
                    return
                }
                do {
                    try await FileImporter.importFromFileURL(
                        fileURL: fileURL,
                        proteinDataSource: proteinDataSource,
                        statusViewModel: statusViewModel,
                        fileInfo: nil
                    )
                } catch {
                    failedToLoad()
                }
            }
        }
    }
    
    func loadFile(at fileURL: URL) {
        // Access security scoped files (outside the sandbox)
        guard fileURL.startAccessingSecurityScopedResource() else {
            failedToLoad()
            return
        }
        // Disable import actions while processing this action
        willLoadProtein = true
        // Dispatch on background queue, file loading can be slow
        Task(priority: .userInitiated) {
            do {
                try await FileImporter.importFromFileURL(
                    fileURL: fileURL,
                    proteinDataSource: proteinDataSource,
                    statusViewModel: statusViewModel,
                    fileInfo: nil
                )
            } catch {
                failedToLoad()
            }
        }
    }

    private func failedToLoad() {
        // Update state on the main queue
        DispatchQueue.main.sync {
            self.willLoadProtein = false
        }
    }
}

struct ProteinImportView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            ProteinImportView()
        }
    }
}
