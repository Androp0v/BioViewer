//
//  PhotoModeContentHeaderView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 20/12/21.
//

import SwiftUI

struct PhotoModeContentHeaderView: View {
    
    @EnvironmentObject var photoModeViewModel: PhotoModeViewModel
    @State var image: Image?
    
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
            ZStack {
                if photoModeViewModel.isPreviewCreated {
                    image?
                        .resizable()
                        .onDrag {
                            guard let cgImage = photoModeViewModel.image else { return NSItemProvider() }
                            let data = UIImage(cgImage: cgImage).pngData()
                            let provider = NSItemProvider(item: data as NSSecureCoding?, typeIdentifier: "public.png")
                            provider.previewImageHandler = { (handler, _, _) -> Void in
                                handler?(data as NSSecureCoding?, nil)
                            }
                            return provider
                        }
                }
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(uiColor: .separator),
                            style: StrokeStyle(lineWidth: 2))
                    .shadow(color: .black.opacity(0.25),
                            radius: 8,
                            x: 0,
                            y: 0)

            }
            .cornerRadius(12)
            .aspectRatio(1.0, contentMode: .fit)
            .frame(maxHeight: 300)
            .onReceive(photoModeViewModel.$isPreviewCreated) { _ in
                if let cgImage = photoModeViewModel.image {
                    self.image = Image(uiImage: UIImage(cgImage: cgImage))
                }
            }
            
            // MARK: - Side buttons
            VStack(alignment: .leading, spacing: 12) {
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
                
                Button(action: {
                    // TO-DO
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
