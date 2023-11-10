//
//  FileCompositionChartView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 2/7/23.
//

import Charts
import SwiftUI

struct FileCompositionChartView: View {
    
    let segments: [CompositionItem]
    @Binding var selectedSegment: CompositionItem?
    
    @State var selectedValue: Int?
        
    var body: some View {
        Chart(segments, id: \.id) { segment in
            SectorMark(
                angle: .value("Fraction", segment.count),
                innerRadius: .ratio(0.618),
                angularInset: 1.5
            )
            .cornerRadius(4)
            .foregroundStyle(segment.color)
            .opacity(segmentOpacity(segment: segment))
        }
        .chartAngleSelection(value: $selectedValue)
        .onChange(of: selectedValue) { _, newValue in
            if let newValue {
                withAnimation {
                    setSelectedSegment(from: newValue)
                }
            }
        }
    }
    
    @MainActor private func setSelectedSegment(from value: Int) {
        var currentCount: Int = 0
        for segment in segments {
            let startValue = currentCount
            let endValue = currentCount + segment.count
            if startValue <= value && endValue >= value {
                let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
                hapticFeedback.prepare()
                hapticFeedback.impactOccurred()
                selectedSegment = segment
                return
            }
            currentCount += segment.count
        }
        selectedSegment = nil
    }
    
    private func segmentOpacity(segment: CompositionItem) -> Double {
        guard let selectedSegment else { return 1.0 }
        if segment == selectedSegment {
            return 1.0
        } else {
            return 0.3
        }
    }
}

#Preview {
    FileCompositionChartView(
        segments: [
            CompositionItem(name: "Element A", color: .red, count: 1, fraction: 0.33),
            CompositionItem(name: "Element B", color: .blue, count: 2, fraction: 0.66)
        ],
        selectedSegment: .constant(CompositionItem(name: "Element A", color: .red, count: 1, fraction: 0.33))
    )
}
