//
//  PhotoModeContentHeaderView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 20/12/21.
//

import SwiftUI

struct PhotoModeContentHeaderView: View {
    
    @Environment(PhotoModeViewModel.self) var photoModeViewModel: PhotoModeViewModel
    @Environment(ShutterAnimator.self) var shutterAnimator: ShutterAnimator
            
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            
            // MARK: - Preview image
            PhotoModeViewfinder()
                .environment(photoModeViewModel.shutterAnimator)
            
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
                
                ShareLink(
                    item: ImageExporter().createExportableImage(
                        cgImage: shutterAnimator.cgImage,
                        preferredFileName: nil
                    ),
                    preview: SharePreview("BioViewer Image")
                )
                .disabled(shutterAnimator.image == nil)
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
                .environment(PhotoModeViewModel())
        }
.previewInterfaceOrientation(.portrait)
    }
}
