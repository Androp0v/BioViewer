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
        self.init(device: device, atomCounts: [atomCount], configurationCounts: [configurationCount])
    }
    
    init?(device: MTLDevice, atomCounts: [Int], configurationCounts: [Int]) {

        let verticesPerAtom: Int = 4
        var totalVertexCount = 0
        var totalAtomCount = 0
        for (atomCount, configurationCount) in zip(atomCounts, configurationCounts) {
            totalAtomCount += atomCount * configurationCount
            totalVertexCount += atomCount * configurationCount * verticesPerAtom
        }
        
        // Position buffer
        guard let newPositionBuffer = device.makeBuffer(length: totalVertexCount * MemoryLayout<simd_short2>.stride,
                                                        options: .storageModePrivate) else {
            return nil
        }
        positionBuffer = newPositionBuffer
        
        // Atom world center buffer
        guard let newAtomWorldCenterBuffer = device.makeBuffer(length: totalAtomCount * MemoryLayout<simd_float3>.stride,
                                                               options: .storageModePrivate) else {
            return nil
        }
        atomWorldCenterBuffer = newAtomWorldCenterBuffer
        
        // Billboard mapping buffer
        guard let newBillboardMappingBuffer = device.makeBuffer(length: totalVertexCount * MemoryLayout<simd_short2>.stride,
                                                                options: .storageModePrivate) else {
            return nil
        }
        billboardMappingBuffer = newBillboardMappingBuffer
        
        // Atom radius buffer
        guard let newAtomRadiusBuffer = device.makeBuffer(length: totalAtomCount * MemoryLayout<Int16>.stride,
                                                          options: .storageModePrivate) else {
            return nil
        }
        atomRadiusBuffer = newAtomRadiusBuffer
    }
}
