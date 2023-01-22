//
//  FileCompositionCircleView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 22/1/23.
//

import SwiftUI

struct FileCompositionCircleView: View {
    
    let segments: [CompositionItem]
    let cumulativeSum: [Double]
    
    init(items: [[CompositionItem]]) {
        var segments = [CompositionItem]()
        var cumulativeSum = [Double]()
        
        var currentSum: Double = 0
        for segment in items.reduce([], +) {
            segments.append(segment)
            currentSum += segment.fraction
            cumulativeSum.append(currentSum)
        }
        
        self.segments = segments.reversed()
        self.cumulativeSum = cumulativeSum.reversed()
    }
    
    var body: some View {
        ZStack {
            ForEach(Array(zip(segments, cumulativeSum)), id: \.0) { segment, fractionSum in
                Circle()
                    .trim(from: 0, to: fractionSum)
                    .stroke(
                        segment.color,
                        style: StrokeStyle(lineWidth: 40)
                    )
                    .rotationEffect(.degrees(-90))
            }
        }
    }
}
