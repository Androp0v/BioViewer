//
//  BasicRenderer.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 30/5/21.
//

import Foundation
@preconcurrency import MetalKit
#if canImport(MetalFX)
import MetalFX
#endif
import SwiftUI

@Observable class ProteinRenderer: NSObject {
    
    // MARK: - Constants
    
    let maxBuffersInFlight = 3
    
    // MARK: - Scheduling
    
    var renderThread: Thread?
    /// Actor used to protect mutable state that cannot be modified during draws.
    let mutableState: MutableState
    /// Used to signal that a new frame is ready to be computed by the CPU.
    var frameBoundarySemaphore: DispatchSemaphore
    /// Frame GPU execution time, exponentially averaged.
    var lastFrameGPUTime = CFTimeInterval()
    
    // MARK: - Benchmark
    
    /// Whether the current `ProteinRenderer` is part of a benchmark.
    var isBenchmark: Bool
    /// The GPU execution times for the las N frames in benchmark mode.
    /// Property is `nil` when not in benchmark mode.
    var benchmarkTimes: [CFTimeInterval]?
    /// Number of benchmarked frames.
    var benchmarkedFrames: Int = 0
    
    // MARK: - Metal variables
    
    /// GPU
    var device: MTLDevice
    /// Command queue.
    var commandQueue: MTLCommandQueue?
    /// Resolution of the view
    var viewResolution: CGSize?
    
    /// Shadow depth state.
    var shadowDepthState: MTLDepthStencilState?
    /// Depth state.
    var depthState: MTLDepthStencilState?

    // MARK: - Runtime variables
    
    /// If provided, this will be called at the end of every frame, and should return a drawable that will be presented.
    var getCurrentDrawable: (() -> CAMetalDrawable?)?
    
    // MARK: - Render pass descriptors
    
    let shadowRenderPassDescriptor: MTLRenderPassDescriptor = {
        let descriptor = MTLRenderPassDescriptor()
        // Final shadow color texture, unused
        descriptor.colorAttachments[0].loadAction = .dontCare
        descriptor.colorAttachments[0].storeAction = .dontCare
        // Depth-bound pre-pass texture
        descriptor.colorAttachments[1].loadAction = .clear
        descriptor.colorAttachments[1].storeAction = .dontCare
        // Final depth texture (Shadow Map)
        descriptor.depthAttachment.loadAction = .clear
        descriptor.depthAttachment.storeAction = .store
        
        return descriptor
    }()
    
    let impostorRenderPassDescriptor: MTLRenderPassDescriptor = {
        let descriptor = MTLRenderPassDescriptor()
        // Final drawable texture
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].storeAction = .store
        // Depth-bound pre-pass texture
        descriptor.colorAttachments[1].loadAction = .clear
        descriptor.colorAttachments[1].storeAction = .dontCare
        // Final depth texture
        descriptor.depthAttachment.loadAction = .clear
        descriptor.depthAttachment.storeAction = .dontCare
        
        return descriptor
    }()
    
    let debugPointsRenderPassDescriptor: MTLRenderPassDescriptor = {
        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].loadAction = .load
        descriptor.colorAttachments[0].storeAction = .store
        descriptor.depthAttachment.loadAction = .load
        descriptor.depthAttachment.storeAction = .dontCare
        return descriptor
    }()
    
    // MARK: - Texture descriptors
    
    let shadowDepthDescriptor: MTLDepthStencilDescriptor = {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = MTLCompareFunction.less
        descriptor.isDepthWriteEnabled = true
        return descriptor
    }()

    let depthDescriptor: MTLDepthStencilDescriptor = {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = MTLCompareFunction.less
        descriptor.isDepthWriteEnabled = true
        return descriptor
    }()
    
    // MARK: - Initialization

    init(device: MTLDevice, isBenchmark: Bool) {

        self.device = device

        self.frameBoundarySemaphore = DispatchSemaphore(value: maxBuffersInFlight)
        
        // Setup command queue
        self.commandQueue = device.makeCommandQueue()
        
        // Benchmark code
        self.isBenchmark = isBenchmark
                
        // Protected state
        self.mutableState = MutableState(
            device: device,
            maxBuffersInFlight: maxBuffersInFlight,
            isBenchmark: isBenchmark
        )
        
        if isBenchmark {
            benchmarkTimes = [CFTimeInterval](repeating: .zero, count: BioBenchConfig.numberOfFrames)
        }
        
        // Call super initializer
        super.init()
        
        // Render thread updates
        startRenderThread()
        
        Task {
            await mutableState.createTextures(isBenchmark: isBenchmark)
        }
        
        // Depth state
        shadowDepthState = device.makeDepthStencilState(descriptor: depthDescriptor)
        depthState = device.makeDepthStencilState(descriptor: depthDescriptor)
    }
    
    // MARK: - Render thread
    func startRenderThread() {
        renderThread = Thread { [weak self] in
            while let self, !(self.renderThread?.isCancelled ?? false) {
                RunLoop.current.run(
                    mode: .default,
                    before: Date.distantFuture
                )
            }
            Thread.exit()
        }
        renderThread?.name = "ProteinRenderer Thread"
        renderThread?.start()
    }
}

// MARK: - Drawing
extension ProteinRenderer {
    
    func drawableSizeChanged(to size: CGSize, layer: CAMetalLayer, displayScale: CGFloat) {
        self.viewResolution = size
        Task {
            await mutableState.updateMutableStateForNewViewSize(
                size,
                metalLayer: layer,
                displayScale: displayScale
            )
        }
    }

    // This is called periodically to render the scene contents on display
    func draw(in layer: CAMetalLayer) {
        Task {
            await mutableState.drawFrame(from: self, in: layer)
        }
    }

}
