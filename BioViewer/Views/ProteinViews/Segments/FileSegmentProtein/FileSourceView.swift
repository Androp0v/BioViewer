//
//  FileSourceView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 13/11/21.
//

import SwiftUI

struct FileSourceView: View {
    
    var sourceLines: [String]?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            if let sourceLines = sourceLines {
                ZStack {
                    // TO-DO: This has terrible performance for big files
                    List {
                        ForEach(sourceLines, id: \.self) {
                            Text($0)
                                .font(.system(size: 9.5, design: .monospaced))
                                .foregroundColor(.white)
                                .listRowBackground(Color.black)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
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
        FileSourceView(sourceLines: ["HEADER    RIBOSOME                                07-JAN-07   XXXX \n",
                                     "TITLE     THE CRYSTAL STRUCTURE OF THE LARGE RIBOSOMAL SUBUNIT FROM \n",
                                     "TITLE    2 DEINOCOCCUS RADIODURANS COMPLEXED WITH THE PLEUROMUTILIN \n"])
    }
}
