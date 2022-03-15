//
//  PhotoModeShareButton.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 15/3/22.
//

import SwiftUI

struct PhotoModeShareButton: View {
    
    private enum Constants {
        #if targetEnvironment(macCatalyst)
        static let buttonSize: CGFloat = 16
        #else
        static let buttonSize: CGFloat = 24
        #endif
    }
    
    @EnvironmentObject var photoModeViewModel: PhotoModeViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
        
    var body: some View {
        
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
}

struct PhotoModeShareButton_Previews: PreviewProvider {
    static var previews: some View {
        PhotoModeShareButton()
    }
}
