//
//  CoordinatesView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 24/2/24.
//

import simd
import SwiftUI

struct CoordinatesView: View {
    
    let coordinates: simd_float3?
    
    private let numberFormatter: NumberFormatter = {
        var formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    // MARK: - Init
    
    init(_ coordinates: simd_float3?) {
        self.coordinates = coordinates
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            singleCoordinate(name: "x", coord: coordinates?.x)
            singleCoordinate(name: "y", coord: coordinates?.y)
            singleCoordinate(name: "z", coord: coordinates?.z)
        }
    }
    
    func singleCoordinate(name: String, coord: Float?) -> some View {
        HStack(spacing: 4) {
            Text("\(name)")
                .bold()
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .foregroundStyle(.white)
                .background {
                    UnevenRoundedRectangle(
                        cornerRadii: .init(
                            topLeading: 6.0,
                            bottomLeading: 6.0
                        ),
                        style: .continuous
                    )
                    .fill(.gray)
                }
            Text(formatCoordinate(coord: coord))
                .lineLimit(1)
                .minimumScaleFactor(0.25)
                .padding(.trailing, 4)
                .padding(.vertical, 2)
        }
        .font(.caption)
        .monospaced()
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(.primary, lineWidth: 0.25)
        }
        .background {
            RoundedRectangle(cornerRadius: 6.0, style: .continuous)
                .fill(Color(uiColor: .secondarySystemFill))
        }
    }
    
    // MARK: - Function
    
    func formatCoordinate(coord: Float?) -> String {
        guard let coord else { return "-" }
        return numberFormatter.string(from: NSNumber(value: Double(coord))) ?? "-"
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        CoordinatesView(simd_float3(x: -34.2, y: 44.6, z: -16.8))
    }
    .padding(48)
    .background(.regularMaterial)
}
