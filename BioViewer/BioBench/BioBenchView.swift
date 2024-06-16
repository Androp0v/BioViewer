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
    
    let proteinViewModel: ProteinViewModel
    @State var proteinDataSource = ProteinDataSource()
    @State var colorViewModel = ProteinColorViewModel()
    @State var visualizationViewModel = ProteinVisualizationViewModel()
    @State var shadowsViewModel = ProteinShadowsViewModel()
    @State var statusViewModel = StatusViewModel()
    @State var selectionModel = SelectionModel()
    
    @State private var resolutionViewModel: ResolutionViewModel
    @State private var fpsViewModel: FPSCounterViewModel
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init() {
        let proteinViewModel = ProteinViewModel(isBenchmark: true)
        self.proteinViewModel = proteinViewModel
        self._proteinDataSource = State(initialValue: proteinViewModel.dataSource)
        self._resolutionViewModel = State(initialValue: ResolutionViewModel(renderer: proteinViewModel.renderer))
        self._fpsViewModel = State(initialValue: FPSCounterViewModel(renderer: proteinViewModel.renderer))
    }
    
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
                    ProteinMetalView(
                        proteinViewModel: proteinViewModel,
                        selectionModel: selectionModel
                    )
                    .disabled(true)
                    .onAppear {
                        shadowsViewModel.proteinViewModel = proteinViewModel
                    }
                    
                    if let currentImage = benchmarkViewModel.currentImage {
                        #if os(iOS)
                        Image(uiImage: UIImage(cgImage: currentImage))
                            .resizable()
                        #elseif os(macOS)
                        Image(nsImage: NSImage(cgImage: currentImage, size: CGSize(width: currentImage.width, height: currentImage.height)))
                            .resizable()
                        #endif
                    }
                    
                    StatusOverlayView()
                        .environment(statusViewModel)
                    
                    ZStack(alignment: .bottomLeading) {
                        HStack {
                            Spacer()
                            VStack(spacing: .zero) {
                                Spacer()
                                ResolutionView()
                                    .environment(resolutionViewModel)
                                FPSCounterView()
                                    .environment(fpsViewModel)
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
