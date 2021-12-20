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
    @State var image: Image?
    
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
                ZStack {
                    if photoModeViewModel.isPreviewCreated {
                        image
                    }
                    Rectangle()
                        .background(.red)
                }
                    .aspectRatio(1.0, contentMode: .fit)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .listRowBackground(Color.clear)
                    .onReceive(photoModeViewModel.$isPreviewCreated) { _ in
                        if let cgImage = photoModeViewModel.image {
                            self.image = Image(uiImage: UIImage(cgImage: cgImage))
                        }
                    }
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
                ZStack {
                    Color.black
                    if photoModeViewModel.isPreviewCreated {
                        image?
                            .resizable()
                    }
                }
                .aspectRatio(1.0, contentMode: .fit)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: 300)
                .listRowBackground(Color.clear)
                .onReceive(photoModeViewModel.$isPreviewCreated) { _ in
                    if let cgImage = photoModeViewModel.image {
                        self.image = Image(uiImage: UIImage(cgImage: cgImage))
                    }
                }
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
