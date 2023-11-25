//
//  ShadowBlurStage.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 9/4/23.
//

import Foundation
import MetalKit

extension MutableState {
    
    func shadowBlurPass(
        renderer: ProteinRenderer,
        commandBuffer: MTLCommandBuffer,
        texture: MTLTexture
    ) {
        // Set Metal compute encoder
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }
        
        guard let shadowBlurPipelineState = renderer.shadowBlurPipelineState else {
            return
        }
        
        // Set compute pipeline state for current arguments
        computeEncoder.setComputePipelineState(shadowBlurPipelineState)
        
        computeEncoder.setTexture(texture, index: 0)
        
        // Schedule the threads
        if device.supportsFamily(.common3) {
            // Create threadgroup sizes
            let width = shadowBlurPipelineState.threadExecutionWidth
            let height = shadowBlurPipelineState.maxTotalThreadsPerThreadgroup / width
            let threadsPerThreadgroup = MTLSizeMake(width, height, 1)
            // Create threadgroup grid
            let threadsPerGrid = MTLSize(
                width: texture.width,
                height: texture.height,
                depth: 1
            )
            // Dispatch threads
            computeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        }
        
        // End encoding
        computeEncoder.endEncoding()
    }
}
