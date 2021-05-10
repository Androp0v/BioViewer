//
//  ProteinCameraControlView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/5/21.
//

import SwiftUI

struct ProteinCameraControlView: View {
    var body: some View {
        ZStack {
            Color.black
            VisualEffectView(effect: UIBlurEffect(style: .regular))
            HStack (spacing: 12) {
                Image(systemName: "move.3d")
                    .foregroundColor(.white)
                Image(systemName: "play.fill")
                    .foregroundColor(.white)
                Image(systemName: "camera.fill")
                    .foregroundColor(.white)
            }
        }
        // Width must be N-times the number of icons
        .frame(width: 3*32, height: 32)
        .cornerRadius(8)
    }
}

struct ProteinCameraControlView_Previews: PreviewProvider {
    static var previews: some View {
        ProteinCameraControlView()
            .previewDevice("iPhone 12")
    }
}
