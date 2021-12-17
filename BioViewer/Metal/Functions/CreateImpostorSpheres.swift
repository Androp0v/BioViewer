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
    public func createImpostorSpheres(protein: Protein) -> (vertexData: MTLBuffer?, subunitData: MTLBuffer?, atomTypeData: MTLBuffer?, indexData: MTLBuffer?) {

        let impostorVertexCount = 4
        let impostorTriangleCount = 2
        
        // Create subunit data array
        var subunitData = [Int16]()
        guard let subunits = protein.subunits else {
            NSLog("Unable to create subunit data array buffer: protein has no subunits")
            return (nil, nil, nil, nil)
        }
        for index in 0..<protein.subunitCount {
            subunitData.append(contentsOf: Array(repeating: Int16(index),
                                                 count: subunits[index].atomCount))
        }
        
        // Get the number of configurations
        let configurationCount = protein.configurationCount

        // Populate buffers
        let generatedVertexBuffer = device.makeBuffer(
            length: protein.atomCount * configurationCount * impostorVertexCount * MemoryLayout<BillboardVertex>.stride
        )
        let subunitBuffer = device.makeBuffer(
            bytes: subunitData,
            length: protein.atomCount * MemoryLayout<Int16>.stride
        )
        let atomTypeBuffer = device.makeBuffer(
            bytes: protein.atomIdentifiers,
            length: protein.atomCount * MemoryLayout<UInt8>.stride
        )
        let generatedIndexBuffer = device.makeBuffer(
            length: protein.atomCount * configurationCount * impostorTriangleCount * 3 * MemoryLayout<UInt32>.stride
        )

        metalDispatchQueue.sync {
            // Populate buffers
            let atomPositionsBuffer = device.makeBuffer(
                bytes: Array(protein.atoms),
                length: protein.atomCount * configurationCount * MemoryLayout<simd_float3>.stride
            )
            let atomTypeBuffer = device.makeBuffer(
                bytes: Array(protein.atomIdentifiers),
                length: protein.atomCount * configurationCount * MemoryLayout<UInt8>.stride
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

            // Set compute pipeline state for current arguments
            computeEncoder.setComputePipelineState(pipelineState)

            // Set buffer contents
            computeEncoder.setBuffer(atomPositionsBuffer,
                                     offset: 0,
                                     index: 0)
            computeEncoder.setBuffer(atomTypeBuffer,
                                     offset: 0,
                                     index: 1)
            computeEncoder.setBuffer(generatedVertexBuffer,
                                     offset: 0,
                                     index: 2)
            computeEncoder.setBuffer(generatedIndexBuffer,
                                     offset: 0,
                                     index: 3)
            
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
        return (generatedVertexBuffer, subunitBuffer, atomTypeBuffer, generatedIndexBuffer)
    }
}
