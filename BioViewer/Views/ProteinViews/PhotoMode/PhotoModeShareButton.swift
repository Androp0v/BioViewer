//
//  PhotoModeShareButton.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 15/3/22.
//

import SwiftUI

struct UIViewHack: UIViewRepresentable {
    
    let underlyingView = UIView()
    
    func makeUIView(context: Context) -> UIView {
        return underlyingView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Do nothing
    }
}

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
    
    private var sourceViewHack = UIViewHack()
    
    var body: some View {
        
        Button(action: {
            ImageExporter().showImageExportSheet(cgImage: photoModeViewModel.image,
                                                 preferredFileName: nil,
                                                 from: sourceViewHack.underlyingView)
        }, label: {
            ZStack(alignment: .topLeading) {
                
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
                
                // Action sheets on iPadOS require a sourceView
                sourceViewHack
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
