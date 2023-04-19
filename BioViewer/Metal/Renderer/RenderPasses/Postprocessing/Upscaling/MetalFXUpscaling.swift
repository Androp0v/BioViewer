//
//  MetalFXUpscaling.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 9/4/23.
//

import Foundation
import MetalKit

extension ProteinRenderer.MutableState {
        
    func metalFXUpscaling(
        renderer: ProteinRenderer,
        commandBuffer: MTLCommandBuffer,
        sourceTexture: MTLTexture,
        depthTexture: MTLTexture,
        motionTexture: MTLTexture?,
        outputTexture: MTLTexture,
        reprojectionData: ReprojectionData?
    ) {
        if let temporalScaler = renderer.metalFXTemporalScaler,
           let motionTexture,
           let reprojectionData {
            
            // MARK: - Fill motion texture
            // Set Metal compute encoder
            
            guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
                return
            }
            computeEncoder.label = "Motion Texture Generation"
            
            guard let motionPipelineState = renderer.motionPipelineState else {
                return
            }
            
            // Set compute pipeline state for current arguments
            computeEncoder.setComputePipelineState(motionPipelineState)
            
            var reprojectionData = reprojectionData
            computeEncoder.setBytes(&reprojectionData, length: MemoryLayout<ReprojectionData>.stride, index: 0)
            // Set the depth texture (used to extract the z-depth of the frame)
            computeEncoder.setTexture(depthTexture, index: 0)
            // Set the motion texture (used to output motion data)
            computeEncoder.setTexture(motionTexture, index: 1)
            
            // Schedule the threads
            if device.supportsFamily(.common3) {
                // Create threadgroup sizes
                let width = motionPipelineState.threadExecutionWidth
                let height = motionPipelineState.maxTotalThreadsPerThreadgroup / width
                let threadsPerThreadgroup = MTLSizeMake(width, height, 1)
                // Create threadgroup grid
                let threadsPerGrid = MTLSize(
                    width: motionTexture.width,
                    height: motionTexture.height,
                    depth: 1
                )
                // Dispatch threads
                computeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
            }
            
            // End encoding
            computeEncoder.endEncoding()
            
            // MARK: - Temporal scaler
            
            temporalScaler.reset = false // TODO: Actual value
            temporalScaler.colorTexture = sourceTexture
            temporalScaler.depthTexture = depthTexture
            temporalScaler.motionTexture = motionTexture
            temporalScaler.outputTexture = outputTexture
            temporalScaler.isDepthReversed = false
            temporalScaler.jitterOffsetX = -reprojectionData.pixel_jitter.x
            temporalScaler.jitterOffsetY = -reprojectionData.pixel_jitter.y
            temporalScaler.encode(commandBuffer: commandBuffer)
            
        } else if let spatialScaler = renderer.metalFXSpatialScaler {
            
            // MARK: - Spatial scaler
            
            spatialScaler.colorTexture = sourceTexture
            spatialScaler.outputTexture = outputTexture
            spatialScaler.encode(commandBuffer: commandBuffer)
            
        } else {
            
            // MARK: - No scaler
            
            // FIXME: Support for devices which don't support Metal 3
        }
    }
}
