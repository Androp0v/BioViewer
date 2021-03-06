//
//  FillColorPass.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 22/1/22.
//

import Foundation
import Metal
import SwiftUI

extension ProteinRenderer {

    // MARK: - Update existing color buffer
    
    public func fillColorPass(commandBuffer: MTLCommandBuffer, colorBuffer: MTLBuffer?, subunitBuffer: MTLBuffer?, atomTypeBuffer: MTLBuffer?, colorFill: FillColorInput) {
          
        var colorFillData = colorFill
        guard let colorBuffer = colorBuffer else { return }
        guard let subunitBuffer = subunitBuffer else { return }
        guard let atomTypeBuffer = atomTypeBuffer else { return }
                
        // Set Metal compute encoder
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }

        // Retrieve pipeline state
        guard let pipelineState = fillColorComputePipelineState else {
            computeEncoder.endEncoding()
            return
        }

        // Set compute pipeline state for current arguments
        computeEncoder.setComputePipelineState(pipelineState)

        // Set buffer contents
        computeEncoder.setBuffer(colorBuffer,
                                 offset: 0,
                                 index: 0)
        computeEncoder.setBuffer(subunitBuffer,
                                 offset: 0,
                                 index: 1)
        computeEncoder.setBuffer(atomTypeBuffer,
                                 offset: 0,
                                 index: 2)
        
        computeEncoder.setBytes(&colorFillData, length: MemoryLayout<FillColorInput>.stride, index: 3)
        
        // Schedule the threads
        if device.supportsFamily(.common3) {
            // Create threads and threadgroup sizes
            let threadsPerArray = MTLSizeMake(colorBuffer.length / MemoryLayout<SIMD3<Int16>>.stride, 1, 1)
            let groupSize = MTLSizeMake(pipelineState.maxTotalThreadsPerThreadgroup, 1, 1)
            // Dispatch threads
            computeEncoder.dispatchThreads(threadsPerArray, threadsPerThreadgroup: groupSize)
        } else {
            // LEGACY: Older devices do not support non-uniform threadgroup sizes
            let arrayLength = colorBuffer.length / MemoryLayout<SIMD4<Int16>>.stride
            MetalLegacySupport.legacyDispatchThreadsForArray(commandEncoder: computeEncoder,
                                                             length: arrayLength,
                                                             pipelineState: pipelineState)
        }

        // REQUIRED: End the compute encoder encoding
        computeEncoder.endEncoding()
        
        // Mark color pass as performed (doesn't mean it has displayed yet)
        self.scene.lastColorPass = CACurrentMediaTime()
    }
}
