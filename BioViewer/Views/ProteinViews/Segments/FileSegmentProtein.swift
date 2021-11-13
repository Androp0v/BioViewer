//
//  FileSegmentProtein.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 9/5/21.
//

import SwiftUI

struct FileSegmentProtein: View {

    @EnvironmentObject var proteinViewModel: ProteinViewModel
    @State var showFileSource: Bool = false

    var body: some View {
            List {
                // First section hast 64pt padding to account for the
                // space under the segmented control.
                Section(header: Text(NSLocalizedString("Loaded file", comment: "")).padding(.top, 48),
                        content: {
                            Text(NSLocalizedString("Number of proteins: ", comment: "") + "\(proteinViewModel.proteinCount)")
                            Text(NSLocalizedString("Number of atoms: ", comment: "") + "\(proteinViewModel.totalAtomCount)")
                            Button(NSLocalizedString("Remove all", comment: ""), action: {
                                proteinViewModel.removeAllProteins()
                            })
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(.red)
                            .disabled(proteinViewModel.proteinCount == 0)
                })
                
                Section(header: Text(NSLocalizedString("File details", comment: "")),
                        content: {
                            Text(NSLocalizedString("PDB ID: ", comment: "")
                                 + "\(proteinViewModel.dataSource.proteins.first?.pdbID ?? "-")")
                            LongTextRow(title: NSLocalizedString("Description: ", comment: ""),
                                        longText: proteinViewModel.dataSource.proteins.first?.description)
                            Button(NSLocalizedString("View raw file", comment: ""), action: {
                                showFileSource.toggle()
                            })
                            .sheet(isPresented: $showFileSource, onDismiss: nil, content: {
                                // TO-DO: Complete file source view
                                Text("Long file source")
                            })
                            .buttonStyle(DefaultButtonStyle())
                            .disabled(proteinViewModel.proteinCount == 0)
                })
            }
            .listStyle(GroupedListStyle())
    }
}

struct FileSegmentProtein_Previews: PreviewProvider {
    static var previews: some View {
        FileSegmentProtein()
            .environmentObject(ProteinViewModel())
    }
}
