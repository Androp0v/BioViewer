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
    let pickerOptions: [String]
    let startIndex: Int
    let endIndex: Int
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init(optionName: String, selectedOption: Binding<Int>, startIndex: Int = 0, pickerOptions: [String]) {
        self.optionName = optionName
        self._selectedOption = selectedOption
        self.startIndex = startIndex
        self.pickerOptions = pickerOptions
        
        self.endIndex = pickerOptions.count + startIndex
    }
    
    var body: some View {
        #if targetEnvironment(macCatalyst)
        // On macOS, this uses the (beautiful) NSPopUpButton instead of
        // navigating to the option.
        Picker(optionName, selection: $selectedOption) {
            ForEach(startIndex..<endIndex) { index in
                // SwiftUI detects selection by tag
                Text(self.pickerOptions[index - startIndex]).tag(index)
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
                ForEach(0..<endIndex) { index in
                    // SwiftUI detects selection by tag
                    Text(self.pickerOptions[index - startIndex]).tag(index)
                }
            }
            .pickerStyle(DefaultPickerStyle())
        } else {
            if #available(iOS 16.0, *) {
                Picker(optionName, selection: $selectedOption.animation()) {
                    ForEach(startIndex..<endIndex) { index in
                        // SwiftUI detects selection by tag
                        Text(self.pickerOptions[index - startIndex]).tag(index)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            } else {
                // Custom picker for iPadOS pre iOS 16 (default MenuPickerStyle
                // on iPadOS did not show the option name pre iOS 16 so it's not
                // very intuitive for our typical options).
                HStack {
                    Text(optionName)
                    Spacer()
                    // We use .animation() here (iPadOS) but not on macOS because
                    // big animations are generally less used on macOS.
                    Picker(optionName, selection: $selectedOption.animation()) {
                        ForEach(startIndex..<endIndex) { index in
                            // SwiftUI detects selection by tag
                            Text(self.pickerOptions[index - startIndex]).tag(index)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
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
