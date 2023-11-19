//
//  BioViewerProgressView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 11/11/23.
//

import SwiftUI

struct BVProgressView: View {
    
    let size: CGFloat
    let strokeWidth: CGFloat
    var halfSize: CGFloat { size / 2 }
    
    init(size: CGFloat, strokeWidth: CGFloat = 4) {
        self.size = size
        self.strokeWidth = strokeWidth
    }
    
    var body: some View {
        TimelineView(.animation) { _ in
            ZStack {
                Group {
                    Path { path in
                        path.move(to: pathPoint(0, reversed: false, pointCount: 1000))
                        for i in 1..<1000 {
                            path.addLine(to: pathPoint(i, reversed: false, pointCount: 1000))
                        }
                    }
                    .stroke(style: .init(lineWidth: strokeWidth, lineJoin: .round))
                    Path { path in
                        path.move(to: pathPoint(0, reversed: true, pointCount: 1000))
                        for i in 1..<1000 {
                            path.addLine(to: pathPoint(i, reversed: true, pointCount: 1000))
                        }
                    }
                    .stroke(style: .init(lineWidth: strokeWidth, lineJoin: .round))
                    Path { path in
                        for i in 1..<18 {
                            path.move(to: pathPoint(i, reversed: false, pointCount: 18))
                            path.addLine(to: pathPoint(i, reversed: true, pointCount: 18))
                        }
                    }
                    .stroke(style: .init(lineWidth: strokeWidth, lineJoin: .round))
                }
                .rotationEffect(.degrees(45))
            }
            .frame(width: size, height: size)
            // .background(.red)
        }
    }
    
    func pathPoint(_ iteration: Int, reversed: Bool, pointCount: Int) -> CGPoint {
        let normalized = Double(iteration) / Double(pointCount)
        let scaledX = size * normalized
        let yFrequency = 1.5
        let timeComponent = Date.now.timeIntervalSinceReferenceDate
        let y = sin(yFrequency * (2 * Double.pi) * (normalized + (1 / (4 * yFrequency))) - timeComponent)
        var scaledY = halfSize * y / 5
        if reversed {
            scaledY *= -1
        }
        return CGPoint(x: scaledX, y: scaledY + halfSize)
    }
}

#Preview {
    BVProgressView(size: 128)
}
