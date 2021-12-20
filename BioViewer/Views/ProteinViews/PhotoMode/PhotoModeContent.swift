//
//  PhotoModeContent.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 19/12/21.
//

import SwiftUI

struct PhotoModeContent: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var photoModeViewModel: PhotoModeViewModel
    
    private struct Constants {
        #if targetEnvironment(macCatalyst)
        static let spacing: CGFloat = 24
        #else
        static let spacing: CGFloat = 36
        #endif
    }
        
    var body: some View {
        
        VStack(spacing: 0) {
            PhotoModeContentHeaderView()
                .padding()
            Divider()
            List {
                Section {
                    PickerRow(optionName: NSLocalizedString("Image resolution", comment: ""),
                              selectedOption: $photoModeViewModel.finalTextureSizeOption,
                              pickerOptions: ["1024x1024",
                                              "2048x2048",
                                              "4096x4096"])
                    PickerRow(optionName: NSLocalizedString("Shadow resolution", comment: ""),
                              selectedOption: $photoModeViewModel.shadowResolution,
                              pickerOptions: ["Normal",
                                              "High",
                                              "Very high"])
                    SwitchRow(title: NSLocalizedString("Clear background", comment: ""),
                              toggledVariable: $photoModeViewModel.photoConfig.clearBackground)
                }
                
                // Empty section to add spacing at the bottom of the list
                Section {
                    Spacer()
                        .frame(height: 24)
                        .listRowBackground(Color.clear)
                }
            }
            .environment(\.defaultMinListHeaderHeight, 0)
            .listStyle(DefaultListStyle())
        }
    }
}

struct PhotoModeHeader_Previews: PreviewProvider {
    static var previews: some View {
        PhotoModeContent()
            .environmentObject(PhotoModeViewModel())
    }
}
