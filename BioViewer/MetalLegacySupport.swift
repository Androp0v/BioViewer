//
//  MetalLegacySupport.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 30/4/22.
//

import Foundation
import Metal

class MetalLegacySupport {
    
    static func legacyDispatchThreadsForArray(commandEncoder: MTLComputeCommandEncoder, length: Int, pipelineState: MTLRenderPipelineState) {
        
        let threadsPerThreadGroup = MTLSizeMake(pipelineState.maxTotalThreadsPerThreadgroup, 1, 1)
        let numberOfFullThreadGroups = length / pipelineState.maxTotalThreadsPerThreadgroup
        let fullThreadGroupSize = MTLSizeMake(numberOfFullThreadGroups, 1, 1)
        
        // Dispatch the full threadgroups
        commandEncoder.dispatchThreadgroups(fullThreadGroupSize, threadsPerThreadgroup: threadsPerThreadGroup)
        
        // Dispatch the remaining threads
        let remainingThreads = length - (pipelineState.maxTotalThreadsPerThreadgroup * numberOfFullThreadGroups)
        commandEncoder.dispatchThreadgroups(MTLSizeMake(1, 1, 1), threadsPerThreadgroup: MTLSizeMake(remainingThreads, 1, 1))
    }
}
