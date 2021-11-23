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
                Section(header: Text(NSLocalizedString("Loaded file", comment: ""))
                            .padding(.top, 52)
                            .padding(.bottom, 4),
                        content: {
                            Text(NSLocalizedString("Number of proteins: ", comment: "") + "\(proteinViewModel.proteinCount)")
                            Text(NSLocalizedString("Number of atoms: ", comment: "") + "\(proteinViewModel.totalAtomCount)")
                })
                
                Section(header: Text(NSLocalizedString("File details", comment: ""))
                            .padding(.bottom, 4),
                        content: {
                    
                            let protein = proteinViewModel.dataSource.proteins.first
                    
                            Text(NSLocalizedString("PDB ID: ", comment: "")
                                 + "\(protein?.fileInfo.pdbID ?? "-")")
                            LongTextRow(title: NSLocalizedString("Description: ", comment: ""),
                                        longText: protein?.fileInfo.description)
                            Button(NSLocalizedString("View raw file", comment: ""), action: {
                                showFileSource.toggle()
                            })
                            .sheet(isPresented: $showFileSource, onDismiss: nil, content: {
                                let fileSourceViewModel = FileSourceViewModel(fileInfo: protein?.fileInfo)
                                FileSourceView(sourceViewModel: fileSourceViewModel)
                            })
                            .buttonStyle(DefaultButtonStyle())
                            .disabled(proteinViewModel.proteinCount == 0)
                })
                
                Section(header: Text(NSLocalizedString("Remove proteins", comment: ""))
                            .padding(.bottom, 4),
                        content: {
                            
                            Button(NSLocalizedString("Remove all", comment: ""), action: {
                                proteinViewModel.removeAllProteins()
                            })
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(.red)
                            .disabled(proteinViewModel.proteinCount == 0)
                })
            }
            .environment(\.defaultMinListHeaderHeight, 0)
            .listStyle(GroupedListStyle())
    }
}

struct FileSegmentProtein_Previews: PreviewProvider {
    static var previews: some View {
        FileSegmentProtein()
            .environmentObject(ProteinViewModel())
    }
}
