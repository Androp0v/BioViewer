//
//  PhotoModeContent.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 19/12/21.
//

import SwiftUI

struct PhotoModeContent: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private struct Constants {
        #if targetEnvironment(macCatalyst)
        static let spacing: CGFloat = 24
        #else
        static let spacing: CGFloat = 36
        #endif
    }
    
    struct ListContent: View {
        var body: some View {
            PickerRow(optionName: NSLocalizedString("Image resolution", comment: ""),
                      selectedOption: .constant(1),
                      pickerOptions: ["1024x1024", "2048x2048", "4096x4096"])
            PickerRow(optionName: NSLocalizedString("Shadow resolution", comment: ""),
                      selectedOption: .constant(1),
                      pickerOptions: ["Normal", "High", "Very high"])
            PickerRow(optionName: NSLocalizedString("Shadow smoothing", comment: ""),
                      selectedOption: .constant(1),
                      pickerOptions: ["Normal", "High", "Very high"])
            SwitchRow(title: NSLocalizedString("Clear background", comment: ""),
                      toggledVariable: .constant(true))
        }
    }
        
    var body: some View {
        if horizontalSizeClass == .compact {
            List {
                Rectangle()
                    .background(.black)
                    .aspectRatio(1.0, contentMode: .fit)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .listRowBackground(Color.clear)
                Section(content: {
                    ListContent()
                }, header: {
                    Text(NSLocalizedString("Photo configuration", comment: ""))
                        .font(.headline)
                })
            }
            .listStyle(GroupedListStyle())
        } else {
            List {
                Rectangle()
                    .background(.black)
                    .aspectRatio(1.0, contentMode: .fit)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .listRowBackground(Color.clear)
                Section(content: {
                    ListContent()
                }, header: {
                    Text(NSLocalizedString("Photo configuration", comment: ""))
                        .font(.headline)
                })
            }
            .listStyle(DefaultListStyle())
        }
    }
}

struct PhotoModeHeader_Previews: PreviewProvider {
    static var previews: some View {
        PhotoModeContent()
    }
}
