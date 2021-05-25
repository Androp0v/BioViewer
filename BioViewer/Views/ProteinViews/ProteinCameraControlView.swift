//
//  ProteinCameraControlView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/5/21.
//

import SwiftUI

struct ProteinCameraControlView: View {

    private struct Constants {
        static let buttonSize: CGFloat = 32
        #if targetEnvironment(macCatalyst)
        static var frameWidth: CGFloat { buttonSize * 3 }
        static var frameHeight: CGFloat = 32
        static var buttonScale: Image.Scale = .medium
        #else
        static var frameWidth: CGFloat { buttonSize * 3 + 4 * 12 }
        static var frameHeight: CGFloat = 40
        static var buttonScale: Image.Scale = .large
        #endif
    }

    var body: some View {
        ZStack {
            Color.black
            VisualEffectView(effect: UIBlurEffect(style: .regular))
            HStack(spacing: 12) {
                Image(systemName: "move.3d")
                    .imageScale(Constants.buttonScale)
                    .foregroundColor(.white)
                Image(systemName: "play.fill")
                    .imageScale(Constants.buttonScale)
                    .foregroundColor(.white)
                Image(systemName: "camera.fill")
                    .imageScale(Constants.buttonScale)
                    .foregroundColor(.white)
            }
        }
        // Width must be N-times the number of icons
        .frame(width: Constants.frameWidth, height: Constants.frameHeight)
        .cornerRadius(8)
    }
}

struct ProteinCameraControlView_Previews: PreviewProvider {
    static var previews: some View {
        ProteinCameraControlView()
            .previewDevice("iPhone 12")
    }
}
