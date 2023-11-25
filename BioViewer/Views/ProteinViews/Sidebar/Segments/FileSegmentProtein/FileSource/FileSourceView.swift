//
//  FileSourceView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 13/11/21.
//

import BioViewerFoundation
import SwiftUI

struct FileSourceView: View {
    
    @Environment(FileSourceViewModel.self) var sourceViewModel: FileSourceViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            if let loadedLines = sourceViewModel.loadedLines {
                List {
                    ForEach(loadedLines.indices, id: \.self) { lineIndex in
                        FileSourceRow(lineNumber: lineIndex + 1,
                                      line: loadedLines[lineIndex],
                                      hasWarning: sourceViewModel.hasWarning(index: lineIndex))
                            .onAppear {
                                if sourceViewModel.shouldLoadMore(index: lineIndex) {
                                    sourceViewModel.loadMore()
                                }
                            }
                    }
                }
                .listStyle(PlainListStyle())
                .navigationTitle(NSLocalizedString("Source file", comment: ""))
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(leading:
                    Button(action: {
                        dismiss()
                    }, label: {
                        Text(NSLocalizedString("Close", comment: ""))
                    })
                )
            } else {
                Text(NSLocalizedString("Source text not available", comment: ""))
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarItems(leading:
                        Button(action: {
                            dismiss()
                        }, label: {
                            Text(NSLocalizedString("Close", comment: ""))
                        })
                    )
            }
        }
        .environment(\.defaultMinListHeaderHeight, 0)
    }
}

struct FileSourceView_Previews: PreviewProvider {
    static let viewModel = FileSourceViewModel(fileInfo: ProteinFileInfo(
        pdbID: nil,
        description: nil,
        authors: nil,
        sourceLines:
            [
                "HEADER    RIBOSOME                                07-JAN-07   XXXX \n",
                "TITLE     THE CRYSTAL STRUCTURE OF THE LARGE RIBOSOMAL SUBUNIT FROM \n",
                "TITLE    2 DEINOCOCCUS RADIODURANS COMPLEXED WITH THE PLEUROMUTILIN \n"
            ]
    ))
    static var previews: some View {
        FileSourceView()
            .environment(Self.viewModel)
    }
}
