//
//  BVDismissActionButton.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 11/11/23.
//

import SwiftUI

struct BVDismissActionButton: View {
    
    let closeAction: (() -> Void)
    
    struct Constants {
        #if targetEnvironment(macCatalyst)
        static let buttonSize: CGFloat = 18
        #else
        static let buttonSize: CGFloat = 24
        #endif
    }
    
    var body: some View {
        Button(
            action: {
                closeAction()
            },
            label: {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(
                            width: Constants.buttonSize / 1.5,
                            height: Constants.buttonSize / 1.5
                        )
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .foregroundStyle(.red)
                }
                .frame(width: Constants.buttonSize, height: Constants.buttonSize)
            }
        )
        #if targetEnvironment(macCatalyst)
        .buttonStyle(.plain)
        #endif
        .offset(x: -Constants.buttonSize / 2.5, y: -Constants.buttonSize / 2.5)
    }
}

#Preview {
    ZStack {
        Color.black
        BVDismissActionButton(closeAction: {})
    }
}
