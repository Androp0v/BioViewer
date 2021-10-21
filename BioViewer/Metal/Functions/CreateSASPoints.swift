//
//  CreateSASPoints.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 21/10/21.
//

import Foundation
import Metal

extension MetalScheduler {

    /// Create Solvent-Accessible Surface (SAS) for a given protein.
    /// - Parameters:
    ///   - protein: The protein whose SAS we want to visualize.
    ///   - sceneDelegate: The scene delegate.
    public func createSASPoints(protein: Protein) {

        metalDispatchQueue.sync {

            // Variables
            var probeRadius: Float = 1.4
            let spherePoints: Int = 162

            // Populate buffers
            let atomPositionsBuffer = device.makeBuffer(
                bytes: Array(protein.atoms),
                length: protein.atomCount * MemoryLayout<simd_float3>.stride
            )
            let generatedSpherePositions = device.makeBuffer(
                length: protein.atomCount * spherePoints * MemoryLayout<simd_float3>.stride
            )

            // Make Metal command buffer
            guard let buffer = queue?.makeCommandBuffer() else { return }

            // Set Metal compute encoder
            guard let computeEncoder = buffer.makeComputeCommandEncoder() else { return }

            // Iterate over each atom type
            for atomSection in AtomSectionSequence(protein: protein) {

                // Set the apropiate radius and probe radius as function constants
                var atomRadius = getAtomicRadius(atomType: atomSection.atomIdentifier)

                guard atomSection.length != 0 else { continue }

                // Create the new MTLFunctionConstantValues parameters
                let newFunctionParameters = MTLFunctionConstantValues()
                newFunctionParameters.setConstantValue(&atomRadius, type: .float, index: 0)
                newFunctionParameters.setConstantValue(&probeRadius, type: .float, index: 1)

                // Check if the function needs to be compiled
                if createSASPointsBundle.requiresBuilding(newFunctionParameters: newFunctionParameters) {
                    createSASPointsBundle.createPipelineState(functionName: "createSASPoints",
                                                              library: self.library,
                                                              device: self.device,
                                                              constantValues: newFunctionParameters)
                }

                guard let pipelineState = createSASPointsBundle.getPipelineState(functionParameters: newFunctionParameters) else {
                    return
                }

                // Create threads and threadgroup sizes
                let threadsPerArray = MTLSizeMake(atomSection.length, 1, 1)
                let groupsize = MTLSizeMake(pipelineState.maxTotalThreadsPerThreadgroup, 1, 1)

                // Set compute pipeline state for current arguments
                computeEncoder.setComputePipelineState(pipelineState)

                // Set buffer contents
                computeEncoder.setBuffer(atomPositionsBuffer,
                                         offset: MemoryLayout<simd_float3>.stride * atomSection.startsAt,
                                         index: 0)
                computeEncoder.setBuffer(generatedSpherePositions,
                                         offset: MemoryLayout<simd_float3>.stride * spherePoints * atomSection.startsAt,
                                         index: 1)

                // Dispatch threads
                computeEncoder.dispatchThreads(threadsPerArray, threadsPerThreadgroup: groupsize)

            }

            // REQUIRED: End the compute encoder encoding
            computeEncoder.endEncoding()

            // Commit the buffer contents
            buffer.commit()

            // Wait until the computation is finished!
            buffer.waitUntilCompleted()

            // Remove generated points that are inside other spheres

            // Make Metal command buffer
            guard let buffer = queue?.makeCommandBuffer() else { return }

            // Set Metal compute encoder
            guard let computeEncoder = buffer.makeComputeCommandEncoder() else { return }

            // Create the new MTLFunctionConstantValues parameters
            let newFunctionParameters = MTLFunctionConstantValues()
            newFunctionParameters.setConstantValue(&probeRadius, type: .float, index: 0)

            // Check if the function needs to be compiled
            if removeSASPointsInsideSolidBundle.requiresBuilding(newFunctionParameters: newFunctionParameters) {
                removeSASPointsInsideSolidBundle.createPipelineState(functionName: "removeSASPointsInsideSolid",
                                                                     library: self.library,
                                                                     device: self.device,
                                                                     constantValues: newFunctionParameters)
            }

            guard let pipelineState = removeSASPointsInsideSolidBundle.getPipelineState(functionParameters: newFunctionParameters) else {
                return
            }

            // Create atomRadius buffer
            var atomRadius = [Float32]()
            protein.atomIdentifiers.forEach { atomId in
                atomRadius.append(getAtomicRadius(atomType: atomId))
            }
            let atomRadiusBuffer = device.makeBuffer(
                bytes: atomRadius,
                length: protein.atomCount * MemoryLayout<Float32>.stride
            )

            // Create bitmask buffer
            let bitmaskBuffer = device.makeBuffer(
                length: protein.atomCount * spherePoints * MemoryLayout<CBool>.stride
            )

            // Set buffer contents
            computeEncoder.setBuffer(atomPositionsBuffer,
                                     offset: 0,
                                     index: 0)
            computeEncoder.setBuffer(atomRadiusBuffer,
                                     offset: 0,
                                     index: 1)
            computeEncoder.setBuffer(generatedSpherePositions,
                                     offset: 0,
                                     index: 2)
            computeEncoder.setBuffer(bitmaskBuffer,
                                     offset: 0,
                                     index: 3)

            // Kernel arguments
            var atomCount: Int32 = Int32(protein.atomCount)
            computeEncoder.setBytes(&atomCount, length: MemoryLayout<Int32>.stride, index: 4)

            // Create threads and threadgroup sizes
            let threadsPerArray = MTLSizeMake(protein.atomCount * spherePoints, 1, 1)
            let groupsize = MTLSizeMake(pipelineState.maxTotalThreadsPerThreadgroup, 1, 1)

            // Set compute pipeline state for current arguments
            computeEncoder.setComputePipelineState(pipelineState)

            // Dispatch threads
            computeEncoder.dispatchThreads(threadsPerArray, threadsPerThreadgroup: groupsize)

            // REQUIRED: End the compute encoder encoding
            computeEncoder.endEncoding()

            // Commit the buffer contents
            buffer.commit()

            // Wait until the computation is finished!
            buffer.waitUntilCompleted()

            // Add point cloud to scene
            guard let pointsSAS = generatedSpherePositions?.contents().assumingMemoryBound(to: simd_float3.self) else { return }
            guard let bitmask = bitmaskBuffer?.contents().assumingMemoryBound(to: CBool.self) else { return }

            // TO-DO: add to metal view
        }
    }
}
