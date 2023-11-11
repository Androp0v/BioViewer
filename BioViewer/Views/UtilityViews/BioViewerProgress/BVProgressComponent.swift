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
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: .zero) {
                Text(title)
                    .font(.caption)
                    .bold()
                    .padding(.top, 8)
                BioViewerProgressView(size: 96)
                    .frame(width: 96, height: 96)
                if let progress {
                    ProgressView(value: progress)
                        .padding(.horizontal, 12)
                } else {
                    Spacer()
                        .frame(height: 8)
                }
            }
        }
        .frame(width: 128)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ZStack {
        Color.black
        BVProgressComponent(title: "Title", progress: 0.5)
    }
}
