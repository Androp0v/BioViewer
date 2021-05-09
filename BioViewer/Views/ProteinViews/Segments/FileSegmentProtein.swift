//
//  FileSegmentProtein.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 9/5/21.
//

import SwiftUI

struct FileSegmentProtein: View {
    var body: some View {
            List {
                // First section hast 64pt padding to account for the
                // space under the segmented control.
                Section(header: Text("Loaded files").padding(.top, 64)) {
                    Text("Number of proteins: 1")
                    Text("Number of atoms: 8542")
                }
            }
            .listStyle(GroupedListStyle())
    }
}

struct FileSegmentProtein_Previews: PreviewProvider {
    static var previews: some View {
        FileSegmentProtein()
    }
}
