//
//  SettingsSegmentProtein.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/11/21.
//

import SwiftUI

struct SettingsSegmentProtein: View {
        
    var body: some View {
        List {
            // First section hast 64pt padding to account for the
            // space under the segmented control.
            Section(header: Text(NSLocalizedString("Settings", comment: ""))
                        .padding(.top, 52)
                        .padding(.bottom, 4),
                    content: {
                // TO-DO:
                SwitchRow(title: "Show FPS", toggledVariable: .constant(false))
                SwitchRow(title: "Average framerate", toggledVariable: .constant(false))
                SwitchRow(title: "Prefer RCSB file info", toggledVariable: .constant(false))
            })
        }
        .environment(\.defaultMinListHeaderHeight, 0)
        #if os(iOS)
        .listStyle(GroupedListStyle())
        #endif
    }
}

struct SettingsSegmentProtein_Previews: PreviewProvider {
    static var previews: some View {
        SettingsSegmentProtein()
    }
}
