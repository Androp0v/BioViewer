//
//  PickerRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/5/21.
//

import SwiftUI

struct PickerRow: View {

    var optionName: String
    @Binding var selectedOption: Int
    @State var pickerOptions: [String]
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        #if targetEnvironment(macCatalyst)
        // On macOS, this uses the (beautiful) NSPopUpButton instead of
        // navigating to the option.
        Picker(optionName, selection: $selectedOption) {
            ForEach(0..<pickerOptions.count) { index in
                // SwiftUI detects selection by tag
                Text(self.pickerOptions[index]).tag(index)
            }
        }
        .pickerStyle(MenuPickerStyle())
        #else
        if horizontalSizeClass == .compact {
            // This works great for compact size classes, where the sidebar
            // is on its own NavigationView and pickers can navigate to a
            // new screen with the selection.
            Picker(optionName, selection: $selectedOption) {
                // We don't use .animation() here since on iPhone this is
                // presented on a different view (through navigation).
                ForEach(0..<pickerOptions.count) { index in
                    // SwiftUI detects selection by tag
                    Text(self.pickerOptions[index]).tag(index)
                }
            }
            .pickerStyle(DefaultPickerStyle())
        } else {
            // Custom picker for iPadOS (default MenuPickerStyle on iPadOS
            // does not show the option name no it's not very intuitive for
            // our typical options).
            HStack {
                Text(optionName)
                Spacer()
                // We use .animation() here (iPadOS) but not on macOS because
                // big animations are generally less used on macOS.
                Picker(optionName, selection: $selectedOption.animation()) {
                    ForEach(0..<pickerOptions.count) { index in
                        // SwiftUI detects selection by tag
                        Text(self.pickerOptions[index]).tag(index)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
        #endif
    }
}

struct PickerRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            PickerRow(optionName: "Select one",
                      selectedOption: .constant(0),
                      pickerOptions: ["Option A", "Option B"])
        }
    }
}
