//
//  BVProgressComponent.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 11/11/23.
//

import SwiftUI

struct BVProgressComponent: View {
    
    let title: String
    let progress: Double?
    let error: Error?
    let closeAction: (() -> Void)?
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: .zero) {
                
                Text(title)
                    .font(.caption)
                    .bold()
                    .padding(.top, 8)
                
                if let error {
                    BVProgressFailedView()
                        .frame(width: 96, height: 96)
                    Text(error.localizedDescription)
                        .frame(width: 96)
                        .font(.caption)
                } else {
                    BVProgressView(size: 96)
                        .frame(width: 96, height: 96)
                    if let progress {
                        ProgressView(value: progress)
                        #if targetEnvironment(macCatalyst)
                            .padding(.horizontal, 12)
                        #else
                            .padding(.horizontal, 12)
                            .padding(.bottom, 12)
                        #endif
                    }
                }
            }
            .padding(.bottom, 8)
            .frame(width: 128)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            if let closeAction {
                BVDismissActionButton(closeAction: closeAction)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        BVProgressComponent(title: "Title", progress: 0.5, error: nil, closeAction: nil)
    }
}
