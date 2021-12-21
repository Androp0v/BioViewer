//
//  PhotoModeViewfinder.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 21/12/21.
//

import SwiftUI

struct PhotoModeViewfinder: View {
    
    @State var image: Image?
    @EnvironmentObject var photoModeViewModel: PhotoModeViewModel
    @ObservedObject var shutterAnimator: ShutterAnimator
    
    var body: some View {
        ZStack {
            
            ZStack {
                Image("DefaultViewfinderImage")
                    .resizable()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .colorScheme(.dark)
            }
            .zIndex(1.0)
            
            if shutterAnimator.showSecondShutterCurtain {
                Image("Shutter")
                    .resizable()
                    .zIndex(2.0)
                    .transition(AnyTransition.asymmetric(insertion: .move(edge: .top),
                                                         removal: .move(edge: .bottom)))
            }
            
            if shutterAnimator.showFirstShutterCurtain {
                Image("Shutter")
                    .resizable()
                    .zIndex(3.0)
                    .transition(AnyTransition.asymmetric(insertion: .move(edge: .top),
                                                         removal: .move(edge: .bottom)))
            }
            
            if photoModeViewModel.isPreviewCreated && shutterAnimator.showImage {
                ZStack {
                    Color(uiColor: .systemBackground)
                    image?
                        .resizable()
                        .onDrag {
                            guard let cgImage = photoModeViewModel.image else { return NSItemProvider() }
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
        .onReceive(photoModeViewModel.$isPreviewCreated) { _ in
            if let cgImage = photoModeViewModel.image {
                self.image = Image(uiImage: UIImage(cgImage: cgImage))
            }
        }
    }
}

struct PhotoModeViewfinder_Previews: PreviewProvider {
    static var previews: some View {
        PhotoModeViewfinder(shutterAnimator: PhotoModeViewModel().shutterAnimator)
            .environmentObject(PhotoModeViewModel())
    }
}
