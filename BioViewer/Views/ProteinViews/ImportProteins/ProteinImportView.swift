//
//  ProteinImportView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 25/5/21.
//

import SwiftUI

fileprivate struct ImportRowView: View {

    var title: String
    var imageName: String
    var action: ProteinImportView.ImportAction
    var parent: ProteinImportView

    var body: some View {
        Button(action: {
            parent.launchImportAction(action: action)
        }) {
            HStack(spacing: 10) {
                Image(systemName: imageName)
                    .frame(width: 32, height: 32, alignment: .center)
                Text(title)
                    .frame(width: 200, alignment: .leading)
            }
            .font(.headline)
            .foregroundColor(.white)
        }
    }
}


struct ProteinImportView: View {

    @EnvironmentObject var proteinViewModel: ProteinViewModel
    @State var willLoadProtein: Bool = false

    public enum ImportAction {
        case importFile
        case downloadFromRCSB
        case downloadFromURL
        case sampleProtein
    }

    var body: some View {
        VStack(spacing: 32) {
            ImportRowView(title: NSLocalizedString("Import files", comment: ""),
                          imageName: "square.and.arrow.down",
                          action: ImportAction.importFile,
                          parent: self)
            ImportRowView(title: NSLocalizedString("Download from RCSB", comment: ""),
                          imageName: "arrow.down.doc",
                          action: ImportAction.downloadFromRCSB,
                          parent: self)
            ImportRowView(title: NSLocalizedString("Download from URL", comment: ""),
                          imageName: "link",
                          action: ImportAction.downloadFromURL,
                          parent: self)
            ImportRowView(title: NSLocalizedString("Sample protein", comment: ""),
                          imageName: "puzzlepiece",
                          action: ImportAction.sampleProtein,
                          parent: self)
        }
        .frame(alignment: .leading)
    }

    public func launchImportAction(action: ImportAction) {

        // Avoid user tapping a load action twice before the first one is loaded
        guard willLoadProtein == false else { return }

        switch action {
        case .importFile:
            // Import from file
            // TO-DO: Import form file
            fatalError()
        case .downloadFromRCSB:
            // Download from RCSB
            // TO-DO: Download from RCSB
            fatalError()
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
                guard let proteinSampleFile = Bundle.main.url(forResource: "2OGM", withExtension: "pdb") else {
                    failedToLoad()
                    return
                }
                guard let proteinData = try? Data(contentsOf: proteinSampleFile) else {
                    failedToLoad()
                    return
                }
                proteinViewModel.statusUpdate(statusText: NSLocalizedString("Importing files", comment: ""))
                let rawText = String(decoding: proteinData, as: UTF8.self)
                var protein = parsePDB(rawText: rawText, proteinViewModel: proteinViewModel)
                proteinViewModel.dataSource.addProteinToDataSource(protein: &protein, addToScene: true)
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
