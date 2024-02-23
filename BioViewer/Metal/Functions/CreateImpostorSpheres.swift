//
//  CreateImpostorSpheres.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 21/10/21.
//

import BioViewerFoundation
import Foundation
import Metal

struct CreateImpostorSpheresOutput {
    let vertexBuffer: BillboardVertexBuffers
    let atomElementBuffer: MTLBuffer
    let subunitBuffer: MTLBuffer?
    let atomResidueBuffer: MTLBuffer?
    let atomSecondaryStructureBuffer: MTLBuffer?
    let indexBuffer: MTLBuffer
}

extension MutableState {
    
    /// Create vertex and index data for a protein given the atom positions.
    /// - Parameter protein: The protein to be visualized.
    /// - Returns: ```MTLBuffer``` containing the positions of each vertex and ```MTLBuffer```
    /// specifying how the triangles are constructed.
    public func createImpostorSpheres(
        proteins: [Protein],
        atomRadii: AtomRadii
    ) -> CreateImpostorSpheresOutput? {

        let impostorTriangleCount = 2
        
        // Create subunit data array
        /*
        var subunitData = [Int16]()
        for protein in proteins {
            guard let subunits = protein.subunits else {
                NSLog("Unable to create subunit data array buffer: protein has no subunits")
                return nil
            }
            for index in 0..<protein.subunitCount {
                subunitData.append(contentsOf: Array(repeating: Int16(index),
                                                     count: subunits[index].atomCount))
            }
        }
         */
        var subunitData = [UInt16]()
        for protein in proteins {
            if let atomSubunits = protein.atomChainIDs {
                subunitData.append(contentsOf: atomSubunits.map { $0.rawValue })
            }
        }
        
        // Create atom identifier array
        var atomElementData = [AtomElement]()
        for protein in proteins {
            atomElementData.append(contentsOf: protein.atomElements)
        }
        
        // Create atom residue type array
        var atomResidueType = [UInt8]()
        for protein in proteins {
            if let proteinResidues = protein.atomResidues {
                atomResidueType.append(contentsOf: proteinResidues.map { $0.rawValue })
            }
        }
        
        // Create atom residue type array
        var atomSecondaryStructureType = [UInt8]()
        for protein in proteins {
            if let proteinSecondaryStructure = protein.atomSecondaryStructure {
                atomSecondaryStructureType.append(contentsOf: proteinSecondaryStructure.map { $0.rawValue })
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

        // Populate mandatory buffers
        
        guard let billboardVertexBuffers = BillboardVertexBuffers(
            device: device,
            atomCounts: atomCounts,
            configurationCounts: configurationCounts
        ) else { return nil }
        
        guard let atomTypeBuffer = device.makeBuffer(
            bytes: atomElementData.map { $0.rawValue },
            length: bufferAtomCount * MemoryLayout<AtomElement.RawValue>.stride
        ) else {
            return nil
        }
        
        // Populate optional buffers
        
        var subunitBuffer: MTLBuffer?
        if !subunitData.isEmpty {
            subunitBuffer = device.makeBuffer(
                bytes: subunitData,
                length: subunitData.count * MemoryLayout<Int16>.stride
            )
        } else {
            BioViewerLogger.shared.log(
                type: .warning,
                category: .proteinRenderer,
                message: "Creating empty atom subunit buffer."
            )
            subunitBuffer = device.makeBuffer(length: bufferAtomCount * MemoryLayout<ChainID.RawValue>.stride)
        }
                
        var atomResidueBuffer: MTLBuffer?
        if !atomResidueType.isEmpty {
            atomResidueBuffer = device.makeBuffer(
                bytes: atomResidueType,
                length: bufferAtomCount * MemoryLayout<Residue.RawValue>.stride
            )
        } else {
            BioViewerLogger.shared.log(
                type: .warning,
                category: .proteinRenderer,
                message: "Creating empty atom residue buffer."
            )
            atomResidueBuffer = device.makeBuffer(length: bufferAtomCount * MemoryLayout<Residue.RawValue>.stride)
        }
        
        var atomSecondaryStructureBuffer: MTLBuffer?
        if !atomSecondaryStructureType.isEmpty {
            atomSecondaryStructureBuffer = device.makeBuffer(
                bytes: atomSecondaryStructureType,
                length: bufferAtomCount * MemoryLayout<SecondaryStructure.RawValue>.stride
            )
        } else {
            BioViewerLogger.shared.log(
                type: .warning,
                category: .proteinRenderer,
                message: "Creating empty atom secondary structure buffer."
            )
            atomSecondaryStructureBuffer = device.makeBuffer(length: bufferAtomCount * MemoryLayout<SecondaryStructure.RawValue>.stride)
        }
        
        guard let generatedIndexBuffer = device.makeBuffer(
            length: bufferAtomAndConfigurationCount * impostorTriangleCount * 3 * MemoryLayout<UInt32>.stride
        ) else { return nil }

        // Populate buffers
        let atomPositionsBuffer = device.makeBuffer(
            bytes: atomPositionsData,
            length: bufferAtomAndConfigurationCount * MemoryLayout<simd_float3>.stride
        )

        // Make Metal command buffer
        guard let queue = device.makeCommandQueue() else {
            return nil
        }
        guard let buffer = queue.makeCommandBuffer() else {
            return nil
        }

        // Set Metal compute encoder
        guard let computeEncoder = buffer.makeComputeCommandEncoder() else {
            return nil
        }

        // Check if the function needs to be compiled
        if MetalScheduler.shared.createSphereModelBundle.requiresBuilding(newFunctionParameters: nil) {
            MetalScheduler.shared.createSphereModelBundle.createPipelineState(
                functionName: "createImpostorSpheres",
                library: self.device.makeDefaultLibrary(),
                device: self.device,
                constantValues: nil
            )
        }
        guard let pipelineState = MetalScheduler.shared.createSphereModelBundle.getPipelineState(functionParameters: nil) else {
            return nil
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
            billboardVertexBuffers.positionBuffer,
            offset: 0,
            index: 2
        )
        computeEncoder.setBuffer(
            billboardVertexBuffers.atomWorldCenterBuffer,
            offset: 0,
            index: 3
        )
        computeEncoder.setBuffer(
            billboardVertexBuffers.billboardMappingBuffer,
            offset: 0,
            index: 4
        )
        computeEncoder.setBuffer(
            billboardVertexBuffers.atomRadiusBuffer,
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
        computeEncoder.setBuffer(
            uniformBuffer,
            offset: 0,
            index: 7
        )
        
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
        return CreateImpostorSpheresOutput(
            vertexBuffer: billboardVertexBuffers,
            atomElementBuffer: atomTypeBuffer,
            subunitBuffer: subunitBuffer,
            atomResidueBuffer: atomResidueBuffer,
            atomSecondaryStructureBuffer: atomSecondaryStructureBuffer,
            indexBuffer: generatedIndexBuffer
        )
    }
}
