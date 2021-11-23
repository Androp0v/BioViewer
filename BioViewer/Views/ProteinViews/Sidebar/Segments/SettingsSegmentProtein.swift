//
//  SettingsSegmentProtein.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/11/21.
//

import SwiftUI

struct SettingsSegmentProtein: View {
    
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    
    var body: some View {
        List {
            // First section hast 64pt padding to account for the
            // space under the segmented control.
            Section(header: Text(NSLocalizedString("Settings", comment: ""))
                        .padding(.top, 52)
                        .padding(.bottom, 4),
                    content: {

                SwitchRow(title: "Smooth framerate", toggledVariable: .constant(true))
            })
        }
        .environment(\.defaultMinListHeaderHeight, 0)
        .listStyle(GroupedListStyle())
    }
}

struct SettingsSegmentProtein_Previews: PreviewProvider {
    static var previews: some View {
        SettingsSegmentProtein()
    }
}
