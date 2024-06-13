//
//  RangeRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/12/21.
//

import SwiftUI

struct RangeRow: View {
    
    let title: String
    
    struct RangeDelimiter: View {
        
        let isLeftRange: Bool
        
        private enum RangeDelimiterConstants {
            #if targetEnvironment(macCatalyst)
            static let size: CGFloat = 16
            #else
            static let size: CGFloat = 24
            #endif
        }
        
        var body: some View {
            Image(systemName: "triangle.fill")
                .resizable()
                .aspectRatio(1.0, contentMode: .fit)
                .frame(width: RangeDelimiterConstants.size)
                .foregroundColor(.white)
                .rotationEffect(Angle(degrees: isLeftRange ? 90 : -90))
                .shadow(color: .black.opacity(0.2),
                        radius: 4,
                        x: 0,
                        y: 2)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                Text("0 to 300 Å")
                    .foregroundColor(.secondary)
            }
            ZStack {
                Capsule()
                    .frame(height: 4)
                    .padding(.horizontal, 10)
                    .foregroundColor(.accentColor)
                HStack {
                    RangeDelimiter(isLeftRange: true)
                    Spacer()
                    RangeDelimiter(isLeftRange: false)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct RangeRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            RangeRow(title: "Range:")
        }
        .preferredColorScheme(.dark)
    }
}
