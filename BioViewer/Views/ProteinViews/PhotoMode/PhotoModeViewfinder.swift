//
//  PhotoModeViewfinder.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 21/12/21.
//

import SwiftUI

struct PhotoModeViewfinder: View {
    
    @Environment(PhotoModeViewModel.self) var photoModeViewModel: PhotoModeViewModel
    @Environment(ShutterAnimator.self) var shutterAnimator: ShutterAnimator
    
    var body: some View {
        ZStack {
            
            // MARK: - Open shutter background
            ZStack {
                Image("DefaultViewfinderImage")
                    .resizable()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .colorScheme(.dark)
            }
            .zIndex(1.0)
            
            // MARK: - Second shutter curtain
            if shutterAnimator.showSecondShutterCurtain {
                Image("Shutter")
                    .resizable()
                    .zIndex(2.0)
                    .transition(AnyTransition.asymmetric(insertion: .move(edge: .top),
                                                         removal: .move(edge: .bottom)))
            }
            
            // MARK: - First shutter curtain
            if shutterAnimator.showFirstShutterCurtain {
                Image("Shutter")
                    .resizable()
                    .zIndex(3.0)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top),
                        removal: .move(edge: .bottom)
                    ))
            }
            // MARK: - Photo/mirror
            if shutterAnimator.image != nil && shutterAnimator.showImage {
                ZStack {
                    Color(uiColor: .systemBackground)
                    shutterAnimator.image?
                        .resizable()
                        .onDrag {
                            guard let cgImage = shutterAnimator.cgImage else { return NSItemProvider() }
                            let data = UIImage(cgImage: cgImage).pngData()
                            let provider = NSItemProvider(item: data as NSSecureCoding?,
                                                          typeIdentifier: "public.png")
                            provider.previewImageHandler = { (handler, _, _) -> Void in
                                handler?(data as NSSecureCoding?, nil)
                            }
                            return provider
                        }
                }
                .zIndex(4.0)
                .transition(AnyTransition.move(edge: .top))
            }
            
            // MARK: - Container
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(uiColor: .separator),
                        style: StrokeStyle(lineWidth: 2))
                .shadow(color: .black.opacity(0.25),
                        radius: 8,
                        x: 0,
                        y: 0)
                .zIndex(5.0)
        }
        .cornerRadius(12)
        .aspectRatio(1.0, contentMode: .fit)
        .frame(maxHeight: 300)
    }
}

struct PhotoModeViewfinder_Previews: PreviewProvider {
    static var previews: some View {
        PhotoModeViewfinder()
            .environment(ShutterAnimator())
            .environment(PhotoModeViewModel())
    }
}
