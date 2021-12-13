//
//  ProteinCameraControlView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/5/21.
//

import SwiftUI

struct DynamicStructureControlView: View {

    private struct Constants {
        #if targetEnvironment(macCatalyst)
        static let buttonSize: CGFloat = 16
        static let spacing: CGFloat = 12
        static let outerPadding: CGFloat = 6
        #else
        static let buttonSize: CGFloat = 24
        static let spacing: CGFloat = 24
        static let outerPadding: CGFloat = 12
        #endif
    }

    var body: some View {
        HStack(spacing: Constants.spacing) {
            Image(systemName: "backward.frame.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Constants.buttonSize, height: Constants.buttonSize)
                .foregroundColor(.primary)
            Image(systemName: "play.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Constants.buttonSize, height: Constants.buttonSize)
                .foregroundColor(.primary)
            Image(systemName: "forward.frame.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Constants.buttonSize, height: Constants.buttonSize)
                .foregroundColor(.primary)
        }
        .padding(Constants.outerPadding)
        .background(.regularMaterial)
        .cornerRadius(Constants.outerPadding)
    }
}

struct ProteinCameraControlView_Previews: PreviewProvider {
    static var previews: some View {
        DynamicStructureControlView()
            .previewDevice("iPhone 12")
    }
}
