//
//  ProteinImportView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 25/5/21.
//

import SwiftUI

struct ImportRowView: View {

    var title: String
    var imageName: String
    var action: ProteinImportView.ImportAction
    var parent: ProteinImportView

    var body: some View {
        Button(action: {
            parent.launchImportAction(action: action)
        },
               label: {
            HStack(spacing: 10) {
                Image(systemName: imageName)
                    .frame(width: 32, height: 32, alignment: .center)
                Text(title)
                    .frame(width: 200, alignment: .leading)
            }
            .font(.headline)
            .foregroundColor(.white)
        })
    }
}

struct ProteinImportView: View {

    @EnvironmentObject var proteinViewModel: ProteinViewModel
    @State var willLoadProtein: Bool = false
    @State var showRCSBImportSheet: Bool = false
    private var pickerHandler = DocumentPickerDelegate()

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
                ImportRowView(title: NSLocalizedString("Import files", comment: ""),
                              imageName: "square.and.arrow.down",
                              action: ImportAction.importFile,
                              parent: self)
                ImportRowView(title: NSLocalizedString("Download from RCSB", comment: ""),
                              imageName: "arrow.down.doc",
                              action: ImportAction.downloadFromRCSB,
                              parent: self)
                /*
                ImportRowView(title: NSLocalizedString("Download from URL", comment: ""),
                              imageName: "link",
                              action: ImportAction.downloadFromURL,
                              parent: self)
                */
                ImportRowView(title: NSLocalizedString("Sample protein", comment: ""),
                              imageName: "puzzlepiece",
                              action: ImportAction.sampleProtein,
                              parent: self)
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

    public func launchImportAction(action: ImportAction) {

        // Avoid user tapping a load action twice before the first one is loaded
        guard willLoadProtein == false else { return }

        switch action {
        case .importFile:
            // Import from file
            let picker = DocumentPickerViewController(forOpeningContentTypes: [.pdbFiles, .xyzFiles], asCopy: false)
            picker.delegate = pickerHandler
            pickerHandler.onPick = { fileURL in
                // Access security scoped files (outside the sandbox)
                guard fileURL.startAccessingSecurityScopedResource() else {
                    failedToLoad()
                    return
                }
                // Disable import actions while processing this action
                willLoadProtein = true
                // Dispatch on background queue, file loading can be slow
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        try FileImporter.importFromFileURL(fileURL: fileURL,
                                                           proteinViewModel: proteinViewModel,
                                                           fileInfo: nil)
                    } catch {
                        failedToLoad()
                    }
                }
            }
            
            // TO-DO: Improve how the current window is located. This is a hacky workaround.
            for scene in UIApplication.shared.connectedScenes where scene.activationState == .foregroundActive {
                guard let windowSceneDelegate = ((scene as? UIWindowScene)?.delegate as? UIWindowSceneDelegate) else {
                    failedToLoad()
                    return
                }
                guard let window = windowSceneDelegate.window else {
                    failedToLoad()
                    return
                }
                guard let rootViewController = window?.rootViewController else {
                    failedToLoad()
                    return
                }
                
                rootViewController.present(picker, animated: true)
            }
            
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
            DispatchQueue.global(qos: .userInitiated).async {
                guard let fileURL = Bundle.main.url(forResource: "3JBT", withExtension: "pdb") else {
                    failedToLoad()
                    return
                }
                do {
                    try FileImporter.importFromFileURL(fileURL: fileURL,
                                                       proteinViewModel: proteinViewModel,
                                                       fileInfo: nil)
                } catch {
                    failedToLoad()
                }
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
