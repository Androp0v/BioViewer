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
            ImportRowView(title: "Sample protein",
                          imageName: "puzzlepiece",
                          action: 2,
                          parent: self)
        }
        .frame(alignment: .leading)
    }

    public func launchImportAction(action: Int) {
        switch action {
        case 0:
            // Import from file
            fatalError()
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
                .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            ProteinImportView()
        }
    }
}
