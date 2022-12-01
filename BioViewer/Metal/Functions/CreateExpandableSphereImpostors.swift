//
//  CreateExpandableSphereImpostors.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 30/11/22.
//

import Foundation
import Metal

extension MetalScheduler {
    
    /// Create vertex and index data for a protein given the atom positions.
    /// - Parameter protein: The protein to be visualized.
    /// - Returns: ```MTLBuffer``` containing the positions of each vertex and ```MTLBuffer```
    /// specifying how the triangles are constructed.
    public func createExpandableSphereImpostors(
        proteins: [Protein],
        atomRadii: AtomRadii
    ) -> (
        vertexData: ExpandableBillboardBuffers?,
        subunitData: MTLBuffer?,
        atomTypeData: MTLBuffer?
    ) {
        
        // Create subunit data array
        var subunitData = [Int16]()
        for protein in proteins {
            guard let subunits = protein.subunits else {
                NSLog("Unable to create subunit data array buffer: protein has no subunits")
                return (nil, nil, nil)
            }
            for index in 0..<protein.subunitCount {
                subunitData.append(contentsOf: Array(repeating: Int16(index),
                                                     count: subunits[index].atomCount))
            }
        }
        
        // Create atom identifier array
        var atomIdentifierData = [UInt16]()
        for protein in proteins {
            atomIdentifierData.append(contentsOf: protein.atomIdentifiers)
        }
        
        // Create atom positions array
        var atomPositionsData = [simd_float3]()
        for protein in proteins {
            atomPositionsData.append(contentsOf: protein.atoms)
        }
        
        // Get the number of atoms and configurations
        var bufferAtomAndConfigurationCount: Int = 0
        var bufferAtomCount: Int = 0
        var atomCounts = [Int]()
        var configurationCounts = [Int]()
        for protein in proteins {
            bufferAtomAndConfigurationCount += protein.atomCount * protein.configurationCount
            bufferAtomCount += protein.atomCount
            atomCounts.append(protein.atomCount)
            configurationCounts.append(protein.configurationCount)
        }

        // Populate buffers
        let expandableBillboardBuffers = ExpandableBillboardBuffers(
            device: device,
            atomCounts: atomCounts,
            configurationCounts: configurationCounts
        )
        
        let subunitBuffer = device.makeBuffer(
            bytes: subunitData,
            length: subunitData.count * MemoryLayout<Int16>.stride
        )
        let atomTypeBuffer = device.makeBuffer(
            bytes: atomIdentifierData,
            length: bufferAtomCount * MemoryLayout<UInt16>.stride
        )

        metalDispatchQueue.sync {
            // Populate buffers
            let atomPositionsBuffer = device.makeBuffer(
                bytes: atomPositionsData,
                length: bufferAtomAndConfigurationCount * MemoryLayout<simd_float3>.stride
            )
            let atomTypeBuffer = device.makeBuffer(
                bytes: atomIdentifierData,
                length: bufferAtomAndConfigurationCount * MemoryLayout<UInt16>.stride
            )

            // Make Metal command buffer
            guard let buffer = queue?.makeCommandBuffer() else {
                return
            }

            // Set Metal compute encoder
            guard let computeEncoder = buffer.makeComputeCommandEncoder() else {
                return
            }

            // Check if the function needs to be compiled
            if createExpandableSphereModelBundle.requiresBuilding(newFunctionParameters: nil) {
                createExpandableSphereModelBundle.createPipelineState(functionName: "createExpandableBillboardSpheres",
                                                            library: self.library,
                                                            device: self.device,
                                                            constantValues: nil)
            }
            guard let pipelineState = createExpandableSphereModelBundle.getPipelineState(functionParameters: nil) else {
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

            computeEncoder.setBuffer(expandableBillboardBuffers?.atomWorldCenterBuffer,
                                     offset: 0,
                                     index: 3)
            computeEncoder.setBuffer(expandableBillboardBuffers?.atomRadiusBuffer,
                                     offset: 0,
                                     index: 5)
            
            // Set uniform buffer contents
            let uniformBuffer = device.makeBuffer(
                bytes: Array([Int32(bufferAtomCount)]),
                length: MemoryLayout<Int32>.stride
            )
            computeEncoder.setBuffer(uniformBuffer,
                                     offset: 0,
                                     index: 7)
            
            var atomRadii = atomRadii
            computeEncoder.setBytes(&atomRadii, length: MemoryLayout<AtomRadii>.stride, index: 8)
            
            // Schedule the threads
            // Create threads and threadgroup sizes
            let threadsPerArray = MTLSizeMake(bufferAtomAndConfigurationCount, 1, 1)
            let groupSize = MTLSizeMake(pipelineState.maxTotalThreadsPerThreadgroup, 1, 1)
            // Dispatch threads
            computeEncoder.dispatchThreads(threadsPerArray, threadsPerThreadgroup: groupSize)

            // REQUIRED: End the compute encoder encoding
            computeEncoder.endEncoding()

            // Commit the buffer contents
            buffer.commit()

            // Wait until the computation is finished!
            buffer.waitUntilCompleted()
        }
        return (expandableBillboardBuffers, subunitBuffer, atomTypeBuffer)
    }
}
