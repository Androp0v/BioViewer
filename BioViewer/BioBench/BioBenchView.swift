//
//  BioBenchView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 24/1/23.
//

import SwiftUI

// swiftlint:disable all
struct BioBenchView: View {
    
    static let benchmarkResolution: CGFloat = 1440
    
    @StateObject var proteinViewModel = ProteinViewModel(isBenchmark: true)
    @StateObject var proteinDataSource = ProteinDataSource()
    @StateObject var colorViewModel = ProteinColorViewModel()
    @StateObject var visualizationViewModel = ProteinVisualizationViewModel()
    @StateObject var shadowsViewModel = ProteinShadowsViewModel()
    @StateObject var statusViewModel = StatusViewModel()
    
    @State var currentImage: CGImage?
    @State var benchmarkedProteins = [BenchmarkedProtein]()
    
    struct BenchmarkedProtein: Equatable {
        let id = UUID()
        let name: String
        let atoms: Int
        let time: Double
        let std: (Double, Double)
        
        static func == (lhs: BioBenchView.BenchmarkedProtein, rhs: BioBenchView.BenchmarkedProtein) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
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
                
                if let currentImage {
                    Image(uiImage: UIImage(cgImage: currentImage))
                        .resizable()
                        .border(.red)
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
            .padding()
            
            List(benchmarkedProteins, id: \.id) { benchmark in
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }
    
    // MARK: - Functions
    private func runBenchmark() async {
        proteinViewModel.colorViewModel?.colorBy = .subunit
        for pdbID in [
            "1KF1",
            "1A3N",
            "2OGM",
            "3JBT",
            "1CWP",
            "6P4L",
            "5IRE",
            "5FUA",
            "1UF2"
        ] {
            guard let (rawText, byteSize) = try? await RCSBFetch.fetchPDBFile(rcsbid: pdbID) else {
                continue
            }
            let fileInfo = ProteinFileInfo(
                pdbID: pdbID,
                description: "",
                authors: "",
                sourceLines: nil
            )
            await proteinDataSource.removeAllFilesFromDatasource()
            try? await FileImporter.importFileFromRawText(
                rawText: rawText,
                proteinDataSource: proteinDataSource,
                statusViewModel: statusViewModel,
                fileInfo: fileInfo,
                fileName: pdbID,
                fileExtension: "pdb",
                byteSize: byteSize
            )
            proteinViewModel.renderer.scene.updateCameraDistanceToModel(
                distanceToModel: proteinViewModel.renderer.scene.cameraPosition.z * 0.8,
                proteinDataSource: proteinDataSource
            )
            proteinViewModel.renderer.scene.autorotating = true
            proteinViewModel.renderer.benchmarkedFrames = 0
            let waitTask = Task.detached {
                while await proteinViewModel.renderer.benchmarkedFrames < BioBenchConfig.numberOfFrames {
                    // Wait
                }
            }
            _ = await waitTask.result
            guard let benchmarkedTimes = proteinViewModel.renderer.benchmarkTimes else { continue }
            let meanTime = meanTime(measuredTimes: benchmarkedTimes)
            let stdTime = stdTime(measuredTimes: benchmarkedTimes, mean: meanTime)
            benchmarkedProteins.append(
                BenchmarkedProtein(
                    name: pdbID,
                    atoms: proteinDataSource.totalAtomCount,
                    time: meanTime,
                    std: stdTime
                )
            )
            print("BioBench \(benchmarkedProteins.count) (\(pdbID)): \(proteinDataSource.totalAtomCount), \(meanTime), \(stdTime.0), \(stdTime.1)")
            proteinViewModel.renderer.scene.autorotating = false
            currentImage = await proteinViewModel.renderer.protectedMutableState.benchmarkTextures.colorTexture.getCGImage()
        }
    }
    
    private func meanTime(measuredTimes: [CFTimeInterval]) -> Double {
        return measuredTimes.reduce(0.0, { $0 + Double($1) }) / Double(BioBenchConfig.numberOfFrames)
    }
    
    private func stdTime(measuredTimes: [CFTimeInterval], mean: Double) -> (Double, Double) {
        let deviation = sqrt( measuredTimes.reduce(0.0, { $0 + pow($1 - mean, 2) }) / Double(BioBenchConfig.numberOfFrames) )
        return (mean - deviation, mean + deviation)
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
