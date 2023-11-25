//
//  BioBenchResultsView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 14/11/23.
//

import Charts
import SwiftUI

struct BioBenchResultsView: View {
    
    @Environment(BioBenchViewModel.self) var benchmarkViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: .zero) {
                Chart {
                    ForEach(benchmarkViewModel.benchmarkedProteins) { benchmarkedProtein in
                        BarMark(
                            x: .value("FPS", toFPS(benchmarkedProtein.time)),
                            y: .value(benchmarkedProtein.name, benchmarkedProtein.name)
                        )
                        .annotation(position: .trailing, alignment: .trailing, spacing: 4) {
                            Text("\(toFPS(benchmarkedProtein.time))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(2)
                        }
                    }
                }
                .chartXAxisLabel("FPS")
                .padding()
                .frame(height: 400)
                .background(.windowBackground)
                
                Divider()
                
                ForEach(benchmarkViewModel.benchmarkedProteins, id: \.id) { benchmark in
                    VStack(alignment: .leading) {
                        Text("Name: ")
                            .bold()
                        Text("\(benchmark.name)")
                            .frame(maxWidth: .infinity)
                        Text("Atom count: ")
                            .bold()
                        Text("\(benchmark.atoms)")
                        Text("GPU time: ")
                            .bold()
                        Text("\(benchmark.time * 1000) ms (\(toFPS(benchmark.time)) fps)")
                        Text("Standard deviation (ms): ")
                            .bold()
                        Text("\((benchmark.std.0 - benchmark.std.1) * 1000) (\(benchmark.std.0 * 1000), \(benchmark.std.1 * 1000))")
                    }
                    .padding(.vertical)
                }
                .listStyle(.plain)
            }
        }
        .frame(maxWidth: 400, maxHeight: .infinity)
        .background(.windowBackground)
    }
    
    private func toFPS(_ milliseconds: Double) -> Int {
        return Int(1.0 / milliseconds)
    }
}
