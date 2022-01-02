//
//  CreateLinksGeometry.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 29/12/21.
//

import Foundation
import Metal

extension MetalScheduler {
    
    /// Create vertex and index data for a protein given the atom positions.
    /// - Parameter protein: The protein to be visualized.
    /// - Returns: ```MTLBuffer``` containing the positions of each vertex and ```MTLBuffer```
    /// specifying how the triangles are constructed.
    public func createLinksGeometry(linkData: [LinkStruct]) -> (vertexBuffer: MTLBuffer?, indexBuffer: MTLBuffer?) {

        let impostorVertexCount = 8
        let impostorTriangleCount = 8
        
        let linkCount = linkData.count
        
        // Populate buffers
        let generatedVertexBuffer = device.makeBuffer(
            length: linkCount * impostorVertexCount * MemoryLayout<BillboardVertex>.stride
        )
        let generatedIndexBuffer = device.makeBuffer(
            length: linkCount * impostorTriangleCount * 3 * MemoryLayout<UInt32>.stride
        )

        metalDispatchQueue.sync {
            // Populate buffers
            let linkDataBuffer = device.makeBuffer(bytes: Array(linkData),
                                                   length: linkCount * MemoryLayout<LinkStruct>.stride)

            // Make Metal command buffer
            guard let buffer = queue?.makeCommandBuffer() else { return }

            // Set Metal compute encoder
            guard let computeEncoder = buffer.makeComputeCommandEncoder() else { return }

            // Check if the function needs to be compiled
            if createLinksBundle.requiresBuilding(newFunctionParameters: nil) {
                createLinksBundle.createPipelineState(functionName: "create_impostor_links",
                                                      library: self.library,
                                                      device: self.device,
                                                      constantValues: nil)
            }
            guard let pipelineState = createLinksBundle.getPipelineState(functionParameters: nil) else {
                return
            }

            // Set compute pipeline state for current arguments
            computeEncoder.setComputePipelineState(pipelineState)

            // Set buffer contents
            computeEncoder.setBuffer(linkDataBuffer,
                                     offset: 0,
                                     index: 0)
            computeEncoder.setBuffer(generatedVertexBuffer,
                                     offset: 0,
                                     index: 1)
            computeEncoder.setBuffer(generatedIndexBuffer,
                                     offset: 0,
                                     index: 2)
                        
            // Schedule the threads
            if device.supportsFamily(.apple3) {
                // Create threads and threadgroup sizes
                let threadsPerArray = MTLSizeMake(linkCount, 1, 1)
                let groupSize = MTLSizeMake(pipelineState.maxTotalThreadsPerThreadgroup, 1, 1)
                
                // Avoid crashes dispatching too big of a size
                guard threadsPerArray.width <= UInt32.max else {
                    computeEncoder.endEncoding()
                    return
                }
                
                // Dispatch threads
                computeEncoder.dispatchThreads(threadsPerArray, threadsPerThreadgroup: groupSize)
            } else {
                // LEGACY: Older devices do not support non-uniform threadgroup sizes
                let groupSize = MTLSizeMake(pipelineState.maxTotalThreadsPerThreadgroup, 1, 1)
                let threadGroupsPerGrid = MTLSizeMake(Int(ceilf(Float(linkCount)
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
        return (generatedVertexBuffer, generatedIndexBuffer)
    }
}
