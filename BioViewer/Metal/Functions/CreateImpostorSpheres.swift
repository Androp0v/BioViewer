//
//  CreateImpostorSpheres.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 21/10/21.
//

import Foundation
import Metal

extension MetalScheduler {
    /// Create vertex and index data for a protein given the atom positions.
    /// - Parameter protein: The protein to be visualized.
    /// - Returns: ```MTLBuffer``` containing the positions of each vertex and ```MTLBuffer```
    /// specifying how the triangles are constructed.
    public func createImpostorSpheres(protein: Protein) -> (vertexData: MTLBuffer?, atomTypeData: MTLBuffer?, indexData: MTLBuffer?) {

        let impostorVertexCount = 8
        let impostorTriangleCount = 12

        // Populate buffers
        let generatedVertexData = device.makeBuffer(
            length: protein.atomCount * impostorVertexCount * MemoryLayout<GeneratedVertex>.stride
        )
        let atomTypeData = device.makeBuffer(
            bytes: protein.atomIdentifiers,
            length: protein.atomCount * MemoryLayout<UInt8>.stride
        )
        let generatedIndexData = device.makeBuffer(
            length: protein.atomCount * impostorTriangleCount * MemoryLayout<UInt32>.stride
        )

        metalDispatchQueue.sync {
            // Populate buffers
            let atomPositionsBuffer = device.makeBuffer(
                bytes: Array(protein.atoms),
                length: protein.atomCount * MemoryLayout<simd_float3>.stride
            )
            let atomTypeBuffer = device.makeBuffer(
                bytes: Array(protein.atomIdentifiers),
                length: protein.atomCount * MemoryLayout<UInt8>.stride
            )

            // Make Metal command buffer
            guard let buffer = queue?.makeCommandBuffer() else { return }

            // Set Metal compute encoder
            guard let computeEncoder = buffer.makeComputeCommandEncoder() else { return }

            // Check if the function needs to be compiled
            if createSphereModelBundle.requiresBuilding(newFunctionParameters: nil) {
                createSphereModelBundle.createPipelineState(functionName: "createImpostorSpheres",
                                                            library: self.library,
                                                            device: self.device,
                                                            constantValues: nil)
            }
            guard let pipelineState = createSphereModelBundle.getPipelineState(functionParameters: nil) else {
                return
            }

            // Create threads and threadgroup sizes
            let threadsPerArray = MTLSizeMake(protein.atomCount, 1, 1)
            let groupsize = MTLSizeMake(pipelineState.maxTotalThreadsPerThreadgroup, 1, 1)

            // Set compute pipeline state for current arguments
            computeEncoder.setComputePipelineState(pipelineState)

            // Set buffer contents
            computeEncoder.setBuffer(atomPositionsBuffer,
                                     offset: 0,
                                     index: 0)
            computeEncoder.setBuffer(atomTypeBuffer,
                                     offset: 0,
                                     index: 1)
            computeEncoder.setBuffer(generatedVertexData,
                                     offset: 0,
                                     index: 2)
            computeEncoder.setBuffer(generatedIndexData,
                                     offset: 0,
                                     index: 3)

            // Dispatch threads
            computeEncoder.dispatchThreads(threadsPerArray, threadsPerThreadgroup: groupsize)

            // REQUIRED: End the compute encoder encoding
            computeEncoder.endEncoding()

            // Commit the buffer contents
            buffer.commit()

            // Wait until the computation is finished!
            buffer.waitUntilCompleted()
        }
        return (generatedVertexData, atomTypeData, generatedIndexData)
    }
}
