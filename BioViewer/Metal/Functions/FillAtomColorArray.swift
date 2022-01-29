//
//  FillAtomColorArray.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 22/1/22.
//

import Foundation
import Metal

extension MetalScheduler {

    public func createAtomColorArray(protein: Protein, atomTypeBuffer: MTLBuffer, color: CGColor) -> MTLBuffer? {
        
        // Get the number of configurations
        let configurationCount = protein.configurationCount
        
        // WORKAROUND: The memory layout should conform to simd_half3's stride, which is
        // syntactic sugar for SIMD3<Float16>, but Float16 is (still) unavailable on macOS
        // due to lack of support on x86. We assume SIMD3<Int16> is packed in the same way
        // Metal packs the half3 type.
        let generatedColorBuffer = device.makeBuffer(
            length: protein.atomCount * configurationCount * MemoryLayout<SIMD3<Int16>>.stride
        )
        
        var colorInput = FillColorInput()
        
        colorInput.colorBySubunit = 0
        
        colorInput.atom_color.0 = simd_float4(0.423, 0.733, 0.235, 1.0) // Carbon
        colorInput.atom_color.1 = simd_float4(0.517, 0.517, 0.517, 1.0) // Hydrogen
        colorInput.atom_color.2 = simd_float4(0.091, 0.148, 0.556, 1.0) // Nitrogen
        colorInput.atom_color.3 = simd_float4(1.000, 0.149, 0.000, 1.0) // Oxygen
        colorInput.atom_color.4 = simd_float4(1.000, 0.780, 0.349, 1.0) // Sulfur
        colorInput.atom_color.5 = simd_float4(0.517, 0.517, 0.517, 1.0) // Others
        
        metalDispatchQueue.sync {

            // Make Metal command buffer
            guard let buffer = queue?.makeCommandBuffer() else {
                return
            }

            // Set Metal compute encoder
            guard let computeEncoder = buffer.makeComputeCommandEncoder() else {
                return
            }

            // Check if the function needs to be compiled
            if fillColorArrayBundle.requiresBuilding(newFunctionParameters: nil) {
                fillColorArrayBundle.createPipelineState(functionName: "fill_color_buffer",
                                                            library: self.library,
                                                            device: self.device,
                                                            constantValues: nil)
            }
            guard let pipelineState = fillColorArrayBundle.getPipelineState(functionParameters: nil) else {
                return
            }

            // Set compute pipeline state for current arguments
            computeEncoder.setComputePipelineState(pipelineState)

            // Set buffer contents
            computeEncoder.setBuffer(generatedColorBuffer,
                                     offset: 0,
                                     index: 0)
            computeEncoder.setBuffer(atomTypeBuffer,
                                     offset: 0,
                                     index: 1)
            
            computeEncoder.setBytes(&colorInput, length: MemoryLayout<FillColorInput>.stride, index: 2)
            
            // Schedule the threads
            if device.supportsFamily(.apple3) {
                // Create threads and threadgroup sizes
                let threadsPerArray = MTLSizeMake(protein.atomCount * configurationCount, 1, 1)
                let groupSize = MTLSizeMake(pipelineState.maxTotalThreadsPerThreadgroup, 1, 1)
                // Dispatch threads
                computeEncoder.dispatchThreads(threadsPerArray, threadsPerThreadgroup: groupSize)
            } else {
                // LEGACY: Older devices do not support non-uniform threadgroup sizes
                let groupSize = MTLSizeMake(pipelineState.maxTotalThreadsPerThreadgroup, 1, 1)
                let threadGroupsPerGrid = MTLSizeMake(Int(ceilf(Float(protein.atomCount * configurationCount)
                                                                / Float(pipelineState.maxTotalThreadsPerThreadgroup))), 1, 1)
                // Dispatch threadgroups
                computeEncoder.dispatchThreadgroups(threadGroupsPerGrid, threadsPerThreadgroup: groupSize)
            }

            // REQUIRED: End the compute encoder encoding
            computeEncoder.endEncoding()

            // Commit the buffer contents
            buffer.commit()

            // Wait until the computation is finished!
            buffer.waitUntilCompleted()
        }
        return generatedColorBuffer
    }
}
