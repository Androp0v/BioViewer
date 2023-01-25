//
//  BioBenchView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 24/1/23.
//

import SwiftUI

struct BioBenchView: View {
    
    static let benchmarkResolution: CGFloat = 1440
    
    @StateObject var proteinViewModel = ProteinViewModel(isBenchmark: true)
    @StateObject var proteinDataSource = ProteinDataSource()
    @StateObject var colorViewModel = ProteinColorViewModel()
    @StateObject var visualizationViewModel = ProteinVisualizationViewModel()
    @StateObject var shadowsViewModel = ProteinShadowsViewModel()
    @StateObject var statusViewModel = StatusViewModel()
    
    @State var benchmarkedProteins = [BenchmarkedProtein]()
    
    struct BenchmarkedProtein: Hashable {
        let id = UUID()
        let name: String
        let atoms: Int
        let time: Double
        let std: Double
    }
    
    var body: some View {
        HStack {
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
                
                ZStack(alignment: .bottomLeading) {
                    HStack {
                        VStack(spacing: .zero) {
                            Spacer()
                            ResolutionView(viewModel: ResolutionViewModel(proteinViewModel: proteinViewModel))
                            FPSCounterView(viewModel: FPSCounterViewModel(proteinViewModel: proteinViewModel))
                                .padding()
                        }
                        Spacer()
                    }
                }
                .frame(width: Self.benchmarkResolution / 2, height: Self.benchmarkResolution / 2)
                
                Button(
                    action: {
                        Task {
                            await runBenchmark()
                        }
                    },
                    label: {
                        Text("Start benchmark")
                    }
                )
                .padding()
            }
            
            List(benchmarkedProteins, id: \.self) { benchmark in
                HStack {
                    Text(benchmark.name)
                    Text("\(benchmark.atoms)")
                    Text("\(benchmark.time) (\(Int(1.0 / (benchmark.time / 100.0))))")
                    Text("\(benchmark.std)")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }
    
    // MARK: - Functions
    private func runBenchmark() async {
        guard let fileURL = Bundle.main.url(forResource: "3JBT", withExtension: "pdb") else {
            return
        }
        proteinDataSource.removeAllFilesFromDatasource()
        try? await FileImporter.importFromFileURL(
            fileURL: fileURL,
            proteinDataSource: proteinDataSource,
            statusViewModel: statusViewModel,
            fileInfo: nil
        )
        proteinViewModel.renderer.scene.autorotating = true
        proteinViewModel.renderer.benchmarkedFrames = 0
        let waitTask = Task.detached {
            while await proteinViewModel.renderer.benchmarkedFrames < BioBenchConfig.numberOfFrames {
                // Wait
            }
        }
        _ = await waitTask.result
        guard let benchmarkedTimes = proteinViewModel.renderer.benchmarkTimes else { return }
        let meanTime = meanTime(measuredTimes: benchmarkedTimes)
        let stdTime = stdTime(measuredTimes: benchmarkedTimes, mean: meanTime)
        benchmarkedProteins.append(
            BenchmarkedProtein(
                name: "3JBT",
                atoms: proteinDataSource.totalAtomCount,
                time: meanTime * 100,
                std: stdTime * 100
            )
        )
        proteinViewModel.renderer.scene.autorotating = false
    }
    
    private func meanTime(measuredTimes: [CFTimeInterval]) -> Double {
        return measuredTimes.reduce(0.0, { $0 + Double($1) }) / Double(BioBenchConfig.numberOfFrames)
    }
    
    private func stdTime(measuredTimes: [CFTimeInterval], mean: Double) -> Double {
        return sqrt( measuredTimes.reduce(0.0, { $0 + pow($1 - mean, 2) }) / Double(BioBenchConfig.numberOfFrames) )
    }
}

// MARK: - Previews

struct BioBenchView_Previews: PreviewProvider {
    static var previews: some View {
        BioBenchView()
    }
}
