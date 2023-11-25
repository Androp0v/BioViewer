//
//  CreateBondsGeometry.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 29/12/21.
//

import BioViewerFoundation
import Foundation
import Metal

struct CreateBondsOutput {
    let vertexBuffer: MTLBuffer
    let indexBuffer: MTLBuffer
}

extension MutableState {
    
    /// Create vertex and index data for a protein given the atom positions.
    /// - Parameter protein: The protein to be visualized.
    /// - Returns: ```MTLBuffer``` containing the positions of each vertex and ```MTLBuffer```
    /// specifying how the triangles are constructed.
    public func createBondsGeometry(bondData: [BondStruct]) -> CreateBondsOutput? {

        let impostorVertexCount = 8
        let impostorTriangleCount = 8
        
        let bondCount = bondData.count
        
        // Populate buffers
        guard let generatedVertexBuffer = device.makeBuffer(
            length: bondCount * impostorVertexCount * MemoryLayout<BillboardVertex>.stride
        ) else {
            return nil
        }
        guard let generatedIndexBuffer = device.makeBuffer(
            length: bondCount * impostorTriangleCount * 3 * MemoryLayout<UInt32>.stride
        ) else {
            return nil
        }

        // Populate buffers
        let bondDataBuffer = device.makeBuffer(
            bytes: Array(bondData.map({$0.toRawBondStruct()})),
            length: bondCount * MemoryLayout<BondStruct>.stride
        )

        // Make Metal command buffer
        guard let queue = device.makeCommandQueue() else { return nil }
        guard let buffer = queue.makeCommandBuffer() else { return nil }

        // Set Metal compute encoder
        guard let computeEncoder = buffer.makeComputeCommandEncoder() else { return nil }

        // Check if the function needs to be compiled
        if MetalScheduler.shared.createBondsBundle.requiresBuilding(newFunctionParameters: nil) {
            MetalScheduler.shared.createBondsBundle.createPipelineState(
                functionName: "create_impostor_bonds",
                library: MetalScheduler.shared.library,
                device: self.device,
                constantValues: nil
            )
        }
        guard let pipelineState = MetalScheduler.shared.createBondsBundle.getPipelineState(functionParameters: nil) else {
            return nil
        }

        // Set compute pipeline state for current arguments
        computeEncoder.setComputePipelineState(pipelineState)

        // Set buffer contents
        computeEncoder.setBuffer(
            bondDataBuffer,
            offset: 0,
            index: 0
        )
        computeEncoder.setBuffer(
            generatedVertexBuffer,
            offset: 0,
            index: 1
        )
        computeEncoder.setBuffer(
            generatedIndexBuffer,
            offset: 0,
            index: 2
        )
                    
        // Schedule the threads
        if device.supportsFamily(.common3) {
            // Create threads and threadgroup sizes
            let threadsPerArray = MTLSizeMake(bondCount, 1, 1)
            let groupSize = MTLSizeMake(pipelineState.maxTotalThreadsPerThreadgroup, 1, 1)
            
            // Avoid crashes dispatching too big of a size
            guard threadsPerArray.width <= UInt32.max else {
                computeEncoder.endEncoding()
                return nil
            }
            
            // Dispatch threads
            computeEncoder.dispatchThreads(threadsPerArray, threadsPerThreadgroup: groupSize)
        } else {
            // LEGACY: Older devices do not support non-uniform threadgroup sizes
            let arrayLength = bondCount
            MetalLegacySupport.legacyDispatchThreadsForArray(commandEncoder: computeEncoder,
                                                             length: arrayLength,
                                                             pipelineState: pipelineState)
        }

        // REQUIRED: End the compute encoder encoding
        computeEncoder.endEncoding()

        // Commit the buffer contents
        buffer.commit()

        // Wait until the computation is finished!
        buffer.waitUntilCompleted()

        return CreateBondsOutput(
            vertexBuffer: generatedVertexBuffer,
            indexBuffer: generatedIndexBuffer
        )
    }
}

extension BondStruct {
    func toRawBondStruct() -> RawBondStruct {
        return RawBondStruct(
            atom_A: self.atomA,
            atom_B: self.atomB,
            cylinder_center: self.cylinderCenter,
            bond_radius: self.bondRadius
        )
    }
}
