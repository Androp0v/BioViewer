//
//  ComputeAmbientOcclusion.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 29/4/23.
//

import BioViewerFoundation
import Foundation
import Metal

extension MutableState {
    
    func computeAmbientOcclusion(atomPositions: ContiguousArray<simd_float3>, atomRadii: [Float], boundingVolume: BoundingVolume) {
        
        guard let library else {
            return
        }
        
        // MARK: - Fill sphere buffer
        
        guard var sphereBuffer = device.makeBuffer(
            length: MemoryLayout<Sphere>.stride * atomPositions.count,
            options: .storageModeShared
        ) else {
            return
        }
        let sphereBufferPointer = sphereBuffer.contents().assumingMemoryBound(to: Sphere.self)
        for i in 0..<atomPositions.count {
            sphereBufferPointer[i] = Sphere(
                origin: atomPositions[i],
                radius: 2.0 // FIXME: Actual radius
            )
        }
        
        // MARK: - Setup acceleration structure
        
        // Create the geometry descriptor.
        let sphereGeometryDescriptor = MTLAccelerationStructureBoundingBoxGeometryDescriptor()
        sphereGeometryDescriptor.intersectionFunctionTableOffset = 0
        
        // Provide the buffer and bounding box count.
        sphereGeometryDescriptor.boundingBoxBuffer = sphereBuffer
        sphereGeometryDescriptor.boundingBoxCount = atomPositions.count
        
        // Create the acceleration structure.
        let accelerationStructureDescriptor = MTLPrimitiveAccelerationStructureDescriptor()
        accelerationStructureDescriptor.geometryDescriptors = [sphereGeometryDescriptor]
        
        // Query for acceleration structure sizes.
        let sizes = device.accelerationStructureSizes(descriptor: accelerationStructureDescriptor)
        
        // Allocate the acceleration structure.
        guard let accelerationStructure = device.makeAccelerationStructure(size: sizes.accelerationStructureSize) else {
            return
        }
        
        // Create the scratch buffer.
        guard let scratchBuffer = device.makeBuffer(length: sizes.buildScratchBufferSize, options: .storageModePrivate) else {
            return
        }
        
        // MARK: - Build acceleration structure
        
        guard let commandQueue = device.makeCommandQueue() else {
            return
        }
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }
        guard let commandEncoder = commandBuffer.makeAccelerationStructureCommandEncoder() else {
            return
        }
        
        commandEncoder.build(
            accelerationStructure: accelerationStructure,
            descriptor: accelerationStructureDescriptor,
            scratchBuffer: scratchBuffer,
            scratchBufferOffset: 0
        )
        
        commandEncoder.endEncoding()
        commandBuffer.commit()
        
        // MARK: - Ambient Occlusion descriptor
        
        let ambientOcclusionPipelineDescriptor = MTLComputePipelineDescriptor()
        let ambientOcclusionFunction = library.makeFunction(name: "compute_occlusion_texture")
        ambientOcclusionPipelineDescriptor.computeFunction = ambientOcclusionFunction
        
        // MARK: - Link intersection function
        
        // Load function from Metal library
        guard let sphereIntersectionFunction = library.makeFunction(name: "sphere_intersection_function") else {
            return
        }
        
        // Attach functions to Metal raytracing compute pipeline descriptor
        let linkedFunctions = MTLLinkedFunctions()
        linkedFunctions.functions = [ sphereIntersectionFunction ]
        
        ambientOcclusionPipelineDescriptor.linkedFunctions = linkedFunctions
        
        // MARK: - Ambient Occlusion PSO
        
        guard let ambientOcclusionPipeline = try? device.makeComputePipelineState(
            descriptor: ambientOcclusionPipelineDescriptor,
            options: [],
            reflection: nil
        ) else {
            return
        }
        
        // MARK: - Function table descriptor
        
        let functionTableDescriptor = MTLIntersectionFunctionTableDescriptor()
        functionTableDescriptor.functionCount = 1
        
        let functionTable = ambientOcclusionPipeline.makeIntersectionFunctionTable(descriptor: functionTableDescriptor)
        
        // Get a handle for the intersection function.
        let functionHandle = ambientOcclusionPipeline.functionHandle(function: sphereIntersectionFunction)
        // Insert the function handle into the table.
        functionTable?.setFunction(functionHandle, index: 0)
        
        // Bind intersection function resources.
        functionTable?.setBuffer(sphereBuffer, offset: 0, index: 0)
        
        // MARK: - Compute ambient occlusion
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }
        guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }
        commandEncoder.setComputePipelineState(ambientOcclusionPipeline)
        
        // Bind the intersection function table.
        commandEncoder.setIntersectionFunctionTable(functionTable, bufferIndex: 0)
        
        // TODO: Dispatch threads
        
        // Finish encoding
        commandEncoder.endEncoding()
        commandBuffer.commit()
    }
}
