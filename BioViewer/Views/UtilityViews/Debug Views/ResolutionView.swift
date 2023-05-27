//
//  ResolutionView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 22/5/22.
//

import SwiftUI

@MainActor class ResolutionViewModel: ObservableObject {
    
    let proteinViewModel: ProteinViewModel
    
    private var displayLink: CADisplayLink?
    
    @Published var resolutionString = "-"
    
    init(proteinViewModel: ProteinViewModel) {
        self.proteinViewModel = proteinViewModel
        self.displayLink = CADisplayLink(target: self,
                                         selector: #selector(self.updateFrameTime))
        self.displayLink?.add(to: .main, forMode: .default)
    }
    
    @objc private func updateFrameTime() {
        // Retrieve last GPU frame time.
        let viewResolution = proteinViewModel.renderer.viewResolution
        guard let width = viewResolution?.width else { return }
        guard let height = viewResolution?.height else { return }
        resolutionString = "\(width)x\(height)"
    }
}

struct ResolutionView: View {
    
    @StateObject var viewModel: ResolutionViewModel
    
    var body: some View {
        Text(viewModel.resolutionString)
            .foregroundColor(.white)
            .background(.black)
            .font(.footnote)
    }
}
