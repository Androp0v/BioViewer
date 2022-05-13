//
//  MetalLegacySupport.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 30/4/22.
//

import Foundation
import Metal

class MetalLegacySupport {
    
    static func legacyDispatchThreadsForArray(commandEncoder: MTLComputeCommandEncoder, length: Int, pipelineState: MTLComputePipelineState) {
        
        let threadsPerThreadgroup = MTLSizeMake(pipelineState.maxTotalThreadsPerThreadgroup, 1, 1)
        let numberOfFullThreadgroups = Int(ceilf(Float(length) / Float(pipelineState.maxTotalThreadsPerThreadgroup)))
        let threadgroupSize = MTLSizeMake(numberOfFullThreadgroups, 1, 1)
        
        // Dispatch the threadgroups
        commandEncoder.dispatchThreadgroups(threadgroupSize, threadsPerThreadgroup: threadsPerThreadgroup)
    }
}
