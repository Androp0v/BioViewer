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
    private var lastIndex: Int = 0
    private var currentIndex: Int = 0
    private let maxSavedFrames: Int = 100
    
    init(proteinViewModel: ProteinViewModel) {
        self.proteinViewModel = proteinViewModel
        self.displayLink = CADisplayLink(target: self,
                                         selector: #selector(self.updateFrameTime))
        self.displayLink?.add(to: .main, forMode: .default)
    }
    
    @objc private func updateFrameTime() {
        
        // Retrieve last GPU frame time.
        let newFrameTime = proteinViewModel.renderer.lastFrameGPUTime
        
        // Avoid saving the same frame time several times if the renderer
        // is paused.
        if frameTimeArray.count < maxSavedFrames {
            guard newFrameTime != frameTimeArray.last else { return }
            frameTimeArray.append(newFrameTime)
        } else {
            guard newFrameTime != frameTimeArray[lastIndex] else { return }
            frameTimeArray[currentIndex] = newFrameTime
        }
        lastIndex = currentIndex
        currentIndex = (currentIndex + 1) % maxSavedFrames
        
        // Compute mean of the saved values
        let averageFrameTime = frameTimeArray.reduce(0, +) / Double(frameTimeArray.count)
        let variance = frameTimeArray.reduce(0, {
            $0 + ($1 - averageFrameTime) * ($1 - averageFrameTime)
        })
        averageFPSString = String(format: "FPS: %.0f ± %.0f",
                                  1 / averageFrameTime,
                                  1 / sqrt(averageFrameTime - variance))
    }
}

struct FPSCounterView: View {
    
    @StateObject var viewModel: FPSCounterViewModel
    
    var body: some View {
        Text(viewModel.averageFPSString)
            .foregroundColor(.white)
            .background(.black)
            .monospacedDigit()
    }
}
