//
//  SelectedElementView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/2/24.
//

import SwiftUI

struct SelectedElementView: View {
    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                Rectangle()
                    .frame(width: 64, height: 64)
                    .foregroundColor(Color(uiColor: UIColor.systemBackground))
                Rectangle()
                    .strokeBorder(
                        Color.primary,
                        lineWidth: 2
                    )
                    .frame(width: 64, height: 64)
                Text("K")
                    .font(.largeTitle)
                    .bold()
            }
            .padding()
            
            VStack(alignment: .leading) {
                HStack {
                    Text("**Atomic mass:**")
                    Text("39.09 u")
                        .font(.footnote)
                        .monospaced()
                }
                HStack {
                    Text("**Radius:**")
                    Text("1.00 Å")
                        .font(.footnote)
                        .monospaced()
                }
                HStack {
                    Text("**Coordinates:**")
                    Text("(-34.0, 44.2, 23.8)")
                        .font(.footnote)
                        .monospaced()
                }
            }
            
            Spacer()
        }
    }
}

#Preview {
    SelectedElementView()
}
