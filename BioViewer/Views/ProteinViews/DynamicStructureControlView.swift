//
//  ProteinCameraControlView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/5/21.
//

import SwiftUI

struct DynamicStructureControlView: View {
    
    @EnvironmentObject var scene: MetalScene
    
    private struct Constants {
        #if targetEnvironment(macCatalyst)
        static let buttonSize: CGFloat = 16
        static let spacing: CGFloat = 18
        static let outerPadding: CGFloat = 6
        #else
        static let buttonSize: CGFloat = 24
        static let spacing: CGFloat = 24
        static let outerPadding: CGFloat = 12
        #endif
    }
    
    var body: some View {
        HStack(spacing: Constants.spacing) {
            Button(action: {
                scene.configurationSelector?.previousConfiguration()
            }, label: {
                Image(systemName: "backward.frame.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            })
                .frame(width: Constants.buttonSize, height: Constants.buttonSize)
                .buttonStyle(CameraControlButtonStyle())
                .disabled(scene.isPlaying)
            
            Button(action: {
                scene.isPlaying.toggle()
            }, label: {
                Image(systemName: scene.isPlaying ? "pause.fill" : "play.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            })
                .frame(width: Constants.buttonSize, height: Constants.buttonSize)
                .buttonStyle(CameraControlButtonStyle())
            
            Button(action: {
                scene.configurationSelector?.nextConfiguration()
            }, label: {
                Image(systemName: "forward.frame.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            })
                .frame(width: Constants.buttonSize, height: Constants.buttonSize)
                .buttonStyle(CameraControlButtonStyle())
                .disabled(scene.isPlaying)
        }
        .padding(Constants.outerPadding)
        .background(.regularMaterial)
        .cornerRadius(Constants.outerPadding)
    }
}

// MARK: - Custom button style
private struct CameraControlButtonStyle: ButtonStyle {
    
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.8 : 1.0)
            .foregroundColor(isEnabled ? .primary : .secondary)
    }
}

// MARK: - SwiftUI previews
struct ProteinCameraControlView_Previews: PreviewProvider {
    static var previews: some View {
        DynamicStructureControlView()
            .previewDevice("iPhone 12")
    }
}
