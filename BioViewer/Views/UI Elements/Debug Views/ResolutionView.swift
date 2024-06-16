//
//  ResolutionView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 22/5/22.
//

import SwiftUI

@MainActor @Observable final class ResolutionViewModel {
    
    let renderer: ProteinRenderer
    var resolution: CGSize?
    
    private var displayLink: PlatformDisplayLink?
    
    init(renderer: ProteinRenderer) {
        self.renderer = renderer
        self.displayLink = PlatformDisplayLink {
            Task { @MainActor in
                await self.updateFrameTime()
            }
        }
        self.displayLink?.add(to: .main, forMode: .default)
    }
    
    private func updateFrameTime() async {
        // Retrieve last GPU frame time.
        if renderer.isBenchmark {
            let benchmarkResolution = BenchmarkTextures.benchmarkResolution
            resolution = CGSize(width: benchmarkResolution, height: benchmarkResolution)
        } else {
            resolution = await renderer.mutableState.viewResolution
        }
    }
}

@MainActor struct ResolutionView: View {
    
    @State var viewModel: ResolutionViewModel
    
    var resolutionString: String {
        guard let resolution = viewModel.resolution else {
            return "-"
        }
        return "\(resolution.width)x\(resolution.height)"
    }
    
    var body: some View {
        Text(resolutionString)
            .foregroundColor(.white)
            .background(.black)
            .font(.footnote)
    }
}
