//
//  AppearanceSegmentProtein.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/5/21.
//

import SwiftUI

struct AppearanceSegmentProtein: View {
    var body: some View {
            List {
                // First section hast 64pt padding to account for the
                // space under the segmented control.
                Section(header: Text("General").padding(.top, 64)) {
                    Text("Background color")
                }

                Section(header: Text("Proteins")) {
                    Text("Representation")
                }
            }
            .listStyle(GroupedListStyle())
    }
}

struct AppearanceSegmentProtein_Previews: PreviewProvider {
    static var previews: some View {
        AppearanceSegmentProtein()
    }
}
