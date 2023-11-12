//
//  BioBenchView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 24/1/23.
//

import BioViewerFoundation
import Charts
import SwiftUI

// swiftlint:disable all
struct BioBenchView: View {
    
    static let benchmarkResolution: CGFloat = 1440
    
    @State var benchmarkViewModel = BioBenchViewModel()
    @State var isRunningBenchmark: Bool = false
    
    @StateObject var proteinViewModel = ProteinViewModel(isBenchmark: true)
    @StateObject var proteinDataSource = ProteinDataSource()
    @State var colorViewModel = ProteinColorViewModel()
    @State var visualizationViewModel = ProteinVisualizationViewModel()
    @State var shadowsViewModel = ProteinShadowsViewModel()
    @State var statusViewModel = StatusViewModel()
            
    var body: some View {
        HStack(spacing: .zero) {
            ZStack(alignment: .bottom) {
                ProteinMetalView(proteinViewModel: proteinViewModel)
                    .frame(width: Self.benchmarkResolution / 2, height: Self.benchmarkResolution / 2)
                    .disabled(true)
                    .border(.red)
                    .background(.black)
                    .onAppear {
                        proteinDataSource.proteinViewModel = proteinViewModel
                        proteinViewModel.dataSource = proteinDataSource
                        
                        colorViewModel.proteinViewModel = proteinViewModel
                        proteinViewModel.colorViewModel = colorViewModel
                        
                        visualizationViewModel.proteinViewModel = proteinViewModel
                        proteinViewModel.visualizationViewModel = visualizationViewModel
                        
                        shadowsViewModel.proteinViewModel = proteinViewModel
                        
                        statusViewModel.proteinViewModel = proteinViewModel
                        proteinViewModel.statusViewModel = statusViewModel
                    }
                
                if let currentImage = benchmarkViewModel.currentImage {
                    Image(uiImage: UIImage(cgImage: currentImage))
                        .resizable()
                        .border(.red)
                }
                
                StatusOverlayView()
                    .environment(statusViewModel)
                
                ZStack(alignment: .bottomLeading) {
                    HStack {
                        Spacer()
                        VStack(spacing: .zero) {
                            Spacer()
                            ResolutionView(viewModel: ResolutionViewModel(proteinViewModel: proteinViewModel))
                            FPSCounterView(viewModel: FPSCounterViewModel(proteinViewModel: proteinViewModel))
                                .padding()
                        }
                    }
                }
                .frame(width: Self.benchmarkResolution / 2, height: Self.benchmarkResolution / 2)
                
                Button(
                    action: {
                        withAnimation {
                            isRunningBenchmark = true
                        }
                        Task { @MainActor in
                            await benchmarkViewModel.runBenchmark(
                                proteinViewModel: proteinViewModel,
                                colorViewModel: colorViewModel,
                                proteinDataSource: proteinDataSource,
                                statusViewModel: statusViewModel
                            )
                            withAnimation {
                                isRunningBenchmark = false
                            }
                        }
                    },
                    label: {
                        HStack {
                            Image(systemName: "gauge.high")
                            if !isRunningBenchmark {
                                Text("Start benchmark")
                            } else {
                                Text("Running benchmark")
                            }
                        }
                    }
                )
                .padding()
                .disabled(isRunningBenchmark)
            }
            .padding()
            
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
                .background(.windowBackground)
                
                Divider()
                
                List(benchmarkViewModel.benchmarkedProteins, id: \.id) { benchmark in
                    VStack(alignment: .leading) {
                        Text("Name: ")
                            .bold()
                        Text("\(benchmark.name)")
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
                .background(.windowBackground)
                .listStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }
    
    private func toFPS(_ milliseconds: Double) -> Int {
        return Int(1.0 / milliseconds)
    }
}

// MARK: - Previews

struct BioBenchView_Previews: PreviewProvider {
    static var previews: some View {
        BioBenchView()
    }
}
