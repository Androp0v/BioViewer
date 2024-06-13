//
//  TrajectorySegmentProtein.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 18/12/21.
//

import SwiftUI

struct TrajectorySegmentProtein: View {
        
    var body: some View {
        List {
            // First section hast 64pt padding to account for the
            // space under the segmented control.
            Section(header: Text(NSLocalizedString("Configurations", comment: ""))
                        .padding(.top, 52)
                        .padding(.bottom, 4),
                    content: {
                SliderRow(title: NSLocalizedString("Frames per configuration", comment: ""),
                          value: .constant(23),
                          minValue: 1,
                          maxValue: 100)
                // InputWithButtonRow()
            })
        }
        .environment(\.defaultMinListHeaderHeight, 0)
        #if os(iOS)
        .listStyle(GroupedListStyle())
        #endif
    }
}

struct TrajectorySegmentProtein_Previews: PreviewProvider {
    static var previews: some View {
        TrajectorySegmentProtein()
    }
}
