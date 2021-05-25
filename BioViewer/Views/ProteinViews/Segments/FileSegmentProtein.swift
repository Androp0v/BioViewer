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
                Section(header: Text("Loaded files").padding(.top, 64),
                        content: {
                            Text("Number of proteins: \(proteinViewModel.proteinCount)")
                            Text("Number of atoms: \(proteinViewModel.totalAtomCount)")
                            Button("Remove all", action: {
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
