//
//  ProteinImportView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 25/5/21.
//

import SwiftUI

fileprivate struct ImportRowView: View {

    @State var title: String
    @State var imageName: String
    var action: Int
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

    var body: some View {
        VStack(spacing: 32) {
            ImportRowView(title: "Import files",
                          imageName: "square.and.arrow.down",
                          action: 0,
                          parent: self)
            ImportRowView(title: "Download from RCSB",
                          imageName: "arrow.down.doc",
                          action: 1,
                          parent: self)
            ImportRowView(title: "Download from URL",
                          imageName: "link",
                          action: 2,
                          parent: self)
            ImportRowView(title: "Sample protein",
                          imageName: "puzzlepiece",
                          action: 3,
                          parent: self)
        }
        .frame(alignment: .leading)
    }

    public func launchImportAction(action: Int) {
        switch action {
        case 0:
            // Import from file
            fatalError()
        case 1:
            // Download from RCSB
            fatalError()
        case 2:
            // Download from URL
            fatalError()
        case 3:
            // Import sample protein
            DispatchQueue.global(qos: .utility).async {
                guard let proteinSampleFile = Bundle.main.url(forResource: "2OGM", withExtension: "pdb") else { return }
                guard let proteinData = try? Data(contentsOf: proteinSampleFile) else { return }
                proteinViewModel.statusUpdate(statusText: "Importing files")
                var protein = parsePDB(rawText: String(decoding: proteinData, as: UTF8.self))
                proteinViewModel.dataSource.addProteinToDataSource(protein: &protein, addToScene: true)
            }
        default:
            // TO-DO
            fatalError()
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
