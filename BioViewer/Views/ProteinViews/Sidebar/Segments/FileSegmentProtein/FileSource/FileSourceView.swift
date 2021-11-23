//
//  FileSourceView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 13/11/21.
//

import SwiftUI

struct FileSourceView: View {
    
    @ObservedObject var sourceViewModel: FileSourceViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            if let loadedLines = sourceViewModel.loadedLines {
                // TO-DO: This has terrible performance for big files
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
    static var previews: some View {
        FileSourceView(sourceViewModel: FileSourceViewModel(fileInfo: ProteinFileInfo(pdbID: nil,
                                                                                      description: nil,
                                                                                      authors: nil,
                                                                                      sourceLines:
            ["HEADER    RIBOSOME                                07-JAN-07   XXXX \n",
             "TITLE     THE CRYSTAL STRUCTURE OF THE LARGE RIBOSOMAL SUBUNIT FROM \n",
             "TITLE    2 DEINOCOCCUS RADIODURANS COMPLEXED WITH THE PLEUROMUTILIN \n"])))
    }
}
