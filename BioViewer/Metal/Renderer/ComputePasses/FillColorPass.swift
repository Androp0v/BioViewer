//
//  FillColorPass.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 22/1/22.
//

import Foundation
import Metal
import SwiftUI

extension MutableState {

    // MARK: - Update existing color buffer
    
    public func fillColorPass(
        renderer: ProteinRenderer,
        commandBuffer: MTLCommandBuffer,
        colorBuffer: MTLBuffer?,
        colorFill: FillColorInput
    ) {
          
        var colorFillData = colorFill
        guard let colorBuffer else {
            BioViewerLogger.shared.log(
                type: .warning,
                category: .proteinRenderer,
                message: "Missing color buffer at FillColorPass Compute Pass."
            )
            return
        }
        guard let atomElementBuffer else {
            BioViewerLogger.shared.log(
                type: .warning,
                category: .proteinRenderer,
                message: "Missing atom element buffer at FillColorPass Compute Pass."
            )
            return
        }
        
        // Set Metal compute encoder
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }

        // Retrieve pipeline state
        guard let fillColorComputePipelineState else {
            computeEncoder.endEncoding()
            return
        }

        // Set compute pipeline state for current arguments
        computeEncoder.setComputePipelineState(fillColorComputePipelineState)

        // Set buffer contents
        computeEncoder.setBuffer(
            colorBuffer,
            offset: 0,
            index: 0
        )
        computeEncoder.setBuffer(
            atomElementBuffer,
            offset: 0,
            index: 1
        )
        computeEncoder.setBuffer(
            atomSubunitBuffer,
            offset: 0,
            index: 2
        )
        computeEncoder.setBuffer(
            atomResidueBuffer,
            offset: 0,
            index: 3
        )
        computeEncoder.setBuffer(
            atomSecondaryStructureBuffer,
            offset: 0,
            index: 4
        )
        
        // Create fillColor buffer and fill with data
        let fillColorBuffer = device.makeBuffer(
            bytes: &colorFillData,
            length: MemoryLayout<FillColorInput>.size
        )
        computeEncoder.setBuffer(
            fillColorBuffer,
            offset: 0,
            index: 5
        )
        
        // Total number of threads (used for legacy devices)
        // TODO: Remove once all devices have non-uniform threadgroup size support
        let uniformBuffer = device.makeBuffer(
            bytes: Array([Int32(colorBuffer.length / MemoryLayout<SIMD3<Int16>>.stride)]),
            length: MemoryLayout<Int32>.stride
        )
        computeEncoder.setBuffer(
            uniformBuffer,
            offset: 0,
            index: 6
        )
        
        // Schedule the threads
        if device.supportsFamily(.common3) {
            // Create threads and threadgroup sizes
            let threadsPerArray = MTLSizeMake(colorBuffer.length / MemoryLayout<SIMD3<Int16>>.stride, 1, 1)
            let groupSize = MTLSizeMake(fillColorComputePipelineState.maxTotalThreadsPerThreadgroup, 1, 1)
            // Dispatch threads
            computeEncoder.dispatchThreads(threadsPerArray, threadsPerThreadgroup: groupSize)
        } else {
            // LEGACY: Older devices do not support non-uniform threadgroup sizes
            let arrayLength = colorBuffer.length / MemoryLayout<SIMD4<Int16>>.stride
            MetalLegacySupport.legacyDispatchThreadsForArray(
                commandEncoder: computeEncoder,
                length: arrayLength,
                pipelineState: fillColorComputePipelineState
            )
        }

        // REQUIRED: End the compute encoder encoding
        computeEncoder.endEncoding()
        
        // Mark color pass as performed (doesn't mean it has displayed yet)
        scene.lastColorPass = CACurrentMediaTime()
    }
}
