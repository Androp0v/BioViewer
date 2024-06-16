//
//  FPSCounterView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 15/5/22.
//

import SwiftUI

@MainActor @Observable class FPSCounterViewModel {
    
    let renderer: ProteinRenderer
    var averageFPSString = "-"
    
    private var displayLink: PlatformDisplayLink?
    private var frameTimeArray = [CFTimeInterval]()
    private var lastIndex: Int = 0
    private var currentIndex: Int = 0
    private let maxSavedFrames: Int = 100
    
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
        let newFrameTime = await renderer.lastFrameGPUTime
        
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
    
    @Environment(FPSCounterViewModel.self) var viewModel: FPSCounterViewModel
    
    var body: some View {
        Text(viewModel.averageFPSString)
            .foregroundColor(.white)
            .background(.black)
            .monospacedDigit()
    }
}
