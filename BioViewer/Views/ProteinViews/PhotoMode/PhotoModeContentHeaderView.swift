//
//  PhotoModeContentHeaderView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 20/12/21.
//

import SwiftUI

struct PhotoModeContentHeaderView: View {
    
    @EnvironmentObject var photoModeViewModel: PhotoModeViewModel
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    enum Constants {
        #if targetEnvironment(macCatalyst)
        static let buttonSize: CGFloat = 16
        #else
        static let buttonSize: CGFloat = 24
        #endif
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            
            // MARK: - Preview image
            PhotoModeViewfinder(shutterAnimator: photoModeViewModel.shutterAnimator)
            
            // MARK: - Side buttons
            VStack(alignment: .leading, spacing: 12) {
                
                /*
                Button(action: {
                    // TO-DO
                }, label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: Constants.buttonSize, height: Constants.buttonSize)
                            .padding(4)
                        if horizontalSizeClass != .compact {
                            Text(NSLocalizedString("Save to photos", comment: ""))
                        }
                    }
                })
                    .disabled(!photoModeViewModel.isPreviewCreated)
                    #if targetEnvironment(macCatalyst)
                    .buttonStyle(BorderedProminentButtonStyle())
                    #endif
                */
                
                Button(action: {
                    ImageExporter().showImageExportSheet(cgImage: photoModeViewModel.image,
                                                         preferredFileName: nil)
                }, label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: Constants.buttonSize, height: Constants.buttonSize)
                            .padding(4)
                        if horizontalSizeClass != .compact {
                            Text(NSLocalizedString("Share", comment: ""))
                        }
                    }
                })
                    .disabled(!photoModeViewModel.isPreviewCreated)
                    #if targetEnvironment(macCatalyst)
                    .buttonStyle(BorderedProminentButtonStyle())
                    #endif
            }
            Spacer()
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
}

struct PhotoModeContentHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            PhotoModeContentHeaderView()
                .environmentObject(PhotoModeViewModel())
        }
.previewInterfaceOrientation(.portrait)
    }
}
