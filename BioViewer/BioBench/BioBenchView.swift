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
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var layout: AnyLayout {
        if horizontalSizeClass == .regular {
            return AnyLayout(HStackLayout(spacing: .zero))
        }
        return AnyLayout(VStackLayout())
    }
            
    var body: some View {
        layout {
            VStack {
                ZStack {
                    ProteinMetalView(proteinViewModel: proteinViewModel)
                        .disabled(true)
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
                }
                .border(.red)
                .background(.black)
                .aspectRatio(1.0, contentMode: .fit)
                .padding()
                
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
            .frame(maxWidth: .infinity)
            
            Divider()
            
            BioBenchResultsView()
                .environment(benchmarkViewModel)
        }
        .background(.black)
    }
}

// MARK: - Previews

struct BioBenchView_Previews: PreviewProvider {
    static var previews: some View {
        BioBenchView()
    }
}
