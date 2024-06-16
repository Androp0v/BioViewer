//
//  PhotoModeFooter.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 19/12/21.
//

import SwiftUI

struct PhotoModeFooter: View {
    
    let renderer: ProteinRenderer
    @Environment(PhotoModeViewModel.self) var photoModeViewModel: PhotoModeViewModel
    @Environment(ShutterAnimator.self) var shutterAnimator: ShutterAnimator
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            Button(action: {
                Task {
                    await photoModeViewModel.shutterAnimator.openShutter()
                    try? await renderer.drawHighQualityFrame(
                        renderer: renderer,
                        size: CGSize(width: 2048, height: 2048),
                        photoConfig: photoModeViewModel.photoConfig,
                        photoModeViewModel: photoModeViewModel
                    )
                }
            }, label: {
                HStack {
                    Image(systemName: "camera")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                    Text(NSLocalizedString("Take photo", comment: ""))
                        .bold()
                }
                .padding(4)
                .frame(maxWidth: .infinity)
            })
                .disabled(photoModeViewModel.shutterAnimator.shutterAnimationRunning)
                .buttonStyle(BorderedProminentButtonStyle())
                .padding()
        }
        .background(.regularMaterial)
        .edgesIgnoringSafeArea(.bottom)
    }
}
