//
//  BillboardVertexBuffers.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 9/6/22.
//

import Foundation
import Metal

struct BillboardVertexBuffers {
    let positionBuffer: MTLBuffer
    let atomWorldCenterBuffer: MTLBuffer
    let billboardMappingBuffer: MTLBuffer
    let atomRadiusBuffer: MTLBuffer
    
    init?(device: MTLDevice, atomCount: Int, configurationCount: Int) {

        let verticesPerAtom: Int = 4
        let vertexCount = atomCount * configurationCount * verticesPerAtom
        
        // Position buffer
        guard let newPositionBuffer = device.makeBuffer(length: vertexCount * MemoryLayout<simd_short3>.stride,
                                                        options: .storageModePrivate) else {
            return nil
        }
        positionBuffer = newPositionBuffer
        
        // Atom world center buffer
        guard let newAtomWorldCenterBuffer = device.makeBuffer(length: vertexCount * MemoryLayout<simd_float3>.stride,
                                                               options: .storageModePrivate) else {
            return nil
        }
        atomWorldCenterBuffer = newAtomWorldCenterBuffer
        
        // Billboard mapping buffer
        guard let newBillboardMappingBuffer = device.makeBuffer(length: vertexCount * MemoryLayout<simd_short2>.stride,
                                                                options: .storageModePrivate) else {
            return nil
        }
        billboardMappingBuffer = newBillboardMappingBuffer
        
        // Atom radius buffer
        guard let newAtomRadiusBuffer = device.makeBuffer(length: vertexCount * MemoryLayout<Int16>.stride,
                                                          options: .storageModePrivate) else {
            return nil
        }
        atomRadiusBuffer = newAtomRadiusBuffer
    }
}
