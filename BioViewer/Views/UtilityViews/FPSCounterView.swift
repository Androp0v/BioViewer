//
//  FPSCounterView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 15/5/22.
//

import SwiftUI

class FPSCounterViewModel: ObservableObject {
    
    let proteinViewModel: ProteinViewModel
    
    private var displayLink: CADisplayLink?
    
    @Published var averageFPSString = "-"
    private var frameTimeArray = [CFTimeInterval]()
    private var currentIndex: Int = 0
    private let maxSavedFrames: Int = 100
    
    init(proteinViewModel: ProteinViewModel) {
        self.proteinViewModel = proteinViewModel
        self.displayLink = CADisplayLink(target: self,
                                         selector: #selector(self.updateFrameTime))
        self.displayLink?.add(to: .main, forMode: .default)
    }
    
    @objc private func updateFrameTime() {
        let newFrameTime = proteinViewModel.renderer.lastFrameGPUTime
        
        if frameTimeArray.count < maxSavedFrames {
            frameTimeArray.append(newFrameTime)
        } else {
            frameTimeArray[currentIndex] = newFrameTime
        }
        currentIndex = (currentIndex + 1) % maxSavedFrames
        
        // Mean of the saved values
        let averageFrameTime = frameTimeArray.reduce(0, +) / Double(frameTimeArray.count)
        averageFPSString = String(format: "FPS: %.0f", 1 / averageFrameTime)
    }
}

struct FPSCounterView: View {
    
    @StateObject var viewModel: FPSCounterViewModel
    
    var body: some View {
        Text(viewModel.averageFPSString)
            .foregroundColor(.white)
            .background(.black)
    }
}
