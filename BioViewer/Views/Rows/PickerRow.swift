//
//  PickerRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/5/21.
//

import SwiftUI

struct PickerRow: View {

    let optionName: String
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
            ForEach(startIndex..<endIndex, id: \.self) { index in
                // SwiftUI detects selection by tag
                Text(self.pickerOptions[index - startIndex])
                    .tag(index)
            }
        }
        .pickerStyle(MenuPickerStyle())
        #else
        Picker(optionName, selection: $selectedOption.animation()) {
            ForEach(startIndex..<endIndex, id: \.self) { index in
                // SwiftUI detects selection by tag
                Text(self.pickerOptions[index - startIndex])
                    .tag(index)
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
