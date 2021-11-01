//
//  FileSegmentProtein.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 9/5/21.
//

import SwiftUI

struct FileSegmentProtein: View {

    @EnvironmentObject var proteinViewModel: ProteinViewModel

    var body: some View {
            List {
                // First section hast 64pt padding to account for the
                // space under the segmented control.
                Section(header: Text(NSLocalizedString("Loaded files", comment: "")).padding(.top, 64),
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
