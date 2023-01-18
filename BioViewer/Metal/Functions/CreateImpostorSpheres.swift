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
    public func createImpostorSpheres(proteins: [Protein], atomRadii: AtomRadii) -> (vertexData: BillboardVertexBuffers?, subunitData: MTLBuffer?, atomTypeData: MTLBuffer?, atomResidueData: MTLBuffer?, indexData: MTLBuffer?) {

        let impostorTriangleCount = 2
        
        // Create subunit data array
        var subunitData = [Int16]()
        for protein in proteins {
            guard let subunits = protein.subunits else {
                NSLog("Unable to create subunit data array buffer: protein has no subunits")
                return (nil, nil, nil, nil, nil)
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
        
        // Create atom residue type array
        var atomResidueType = [UInt8]()
        for protein in proteins {
            if let proteinResidues = protein.atomResidues {
                atomResidueType.append(contentsOf: proteinResidues.map { $0.rawValue })
            }
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
        let billboardVertexBuffers = BillboardVertexBuffers(
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
        var atomResidueBuffer: MTLBuffer?
        if !atomResidueType.isEmpty {
            atomResidueBuffer = device.makeBuffer(
                bytes: atomResidueType,
                length: bufferAtomCount * MemoryLayout<UInt8>.stride
            )
        }
        let generatedIndexBuffer = device.makeBuffer(
            length: bufferAtomAndConfigurationCount * impostorTriangleCount * 3 * MemoryLayout<UInt32>.stride
        )

        metalDispatchQueue.sync {
            // Populate buffers
            let atomPositionsBuffer = device.makeBuffer(
                bytes: atomPositionsData,
                length: bufferAtomAndConfigurationCount * MemoryLayout<simd_float3>.stride
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
            if createSphereModelBundle.requiresBuilding(newFunctionParameters: nil) {
                createSphereModelBundle.createPipelineState(
                    functionName: "createImpostorSpheres",
                    library: self.library,
                    device: self.device,
                    constantValues: nil
                )
            }
            guard let pipelineState = createSphereModelBundle.getPipelineState(functionParameters: nil) else {
                return
            }

            // Set compute pipeline state for current arguments
            computeEncoder.setComputePipelineState(pipelineState)

            // Set buffer contents
            computeEncoder.setBuffer(
                atomPositionsBuffer,
                offset: 0,
                index: 0
            )
            computeEncoder.setBuffer(
                atomTypeBuffer,
                offset: 0,
                index: 1
            )
            
            computeEncoder.setBuffer(
                billboardVertexBuffers?.positionBuffer,
                offset: 0,
                index: 2
            )
            computeEncoder.setBuffer(
                billboardVertexBuffers?.atomWorldCenterBuffer,
                offset: 0,
                index: 3
            )
            computeEncoder.setBuffer(
                billboardVertexBuffers?.billboardMappingBuffer,
                offset: 0,
                index: 4
            )
            computeEncoder.setBuffer(
                billboardVertexBuffers?.atomRadiusBuffer,
                offset: 0,
                index: 5
            )
            
            computeEncoder.setBuffer(
                generatedIndexBuffer,
                offset: 0,
                index: 6
            )
            
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
            if device.supportsFamily(.common3) {
                // Create threads and threadgroup sizes
                let threadsPerArray = MTLSizeMake(bufferAtomAndConfigurationCount, 1, 1)
                let groupSize = MTLSizeMake(pipelineState.maxTotalThreadsPerThreadgroup, 1, 1)
                // Dispatch threads
                computeEncoder.dispatchThreads(threadsPerArray, threadsPerThreadgroup: groupSize)
            } else {
                // LEGACY: Older devices do not support non-uniform threadgroup sizes
                MetalLegacySupport.legacyDispatchThreadsForArray(
                    commandEncoder: computeEncoder,
                    length: bufferAtomAndConfigurationCount,
                    pipelineState: pipelineState
                )
            }

            // REQUIRED: End the compute encoder encoding
            computeEncoder.endEncoding()

            // Commit the buffer contents
            buffer.commit()

            // Wait until the computation is finished!
            buffer.waitUntilCompleted()
        }
        return (billboardVertexBuffers, subunitBuffer, atomTypeBuffer, atomResidueBuffer, generatedIndexBuffer)
    }
}
