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

final class ProteinRenderer: NSObject, Sendable {
    
    // MARK: - Constants
    
    let maxBuffersInFlight = 3
    
    // MARK: - Scheduling
    
    /// Actor used to protect mutable state that cannot be modified during draws.
    let mutableState: MutableState
    
    // MARK: - Benchmark
    
    /// Whether the current `ProteinRenderer` is part of a benchmark.
    let isBenchmark: Bool
    
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
    
    // MARK: - Initialization

    init(isBenchmark: Bool) {
        
        // Benchmark code
        self.isBenchmark = isBenchmark
                
        // Protected state
        self.mutableState = MutableState(
            maxBuffersInFlight: maxBuffersInFlight,
            isBenchmark: isBenchmark
        )
        
        // Call super initializer
        super.init()
        
        Task {
            await mutableState.createTextures(isBenchmark: isBenchmark)
        }

    }
}

// MARK: - Drawing

extension ProteinRenderer {
    
    func drawableSizeChanged(to size: CGSize, layer: CAMetalLayer, displayScale: CGFloat) {
        Task(priority: .high) {
            await mutableState.updateMutableStateForNewViewSize(
                size,
                metalLayer: layer,
                displayScale: displayScale
            )
        }
    }

    // This is called periodically to render the scene contents on display
    func draw(in layer: CAMetalLayer) {
        Task(priority: .high) {
            await mutableState.drawFrame(from: self, in: layer)
        }
    }
}
