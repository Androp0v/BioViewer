//
//  PickerRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/5/21.
//

import SwiftUI

struct PickerRow: View {

    var optionName: String
    @Binding var selectedVisualization: Int
    @State var pickerOptions: [String]


    var body: some View {
        #if os(macOS)
        // On macOS, this uses the (beautiful) NSPopUpButton instead of
        // navigating to the option.
        Picker(optionName, selection: $selectedVisualization, content: {
            ForEach(0..<pickerOptions.count) { index in
                // SwiftUI detects selection by tag
                Text(self.pickerOptions[index]).tag(index)
            }
        })
        .pickerStyle(MenuPickerStyle())
        #else
        // This works great for compact size classes, where the sidebar
        // is on its own NavigationView and pickers can navigate to a
        // new screen with the selection.

        // TO-DO: Custom picker for iPadOS non-compact sizes, as there's
        // another NavigationView on the same view hierarchy and the
        // whole screen transitions to the picker, which looks terrible.

        Picker(optionName, selection: $selectedVisualization, content: {
            ForEach(0..<pickerOptions.count) { index in
                // SwiftUI detects selection by tag
                Text(self.pickerOptions[index]).tag(index)
            }
        })
        .pickerStyle(DefaultPickerStyle())
        #endif
    }
}

struct PickerRow_Previews: PreviewProvider {
    static var previews: some View {
        PickerRow(optionName: "Select one",
                  selectedVisualization: .constant(0),
                  pickerOptions: ["Option A", "Option B"])
    }
}
