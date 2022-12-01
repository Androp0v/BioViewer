//
//  ExpandableBillboardBuffers.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 30/11/22.
//

import Foundation
import Metal

struct ExpandableBillboardBuffers {
    let atomWorldCenterBuffer: MTLBuffer
    let atomRadiusBuffer: MTLBuffer
    
    init?(device: MTLDevice, atomCount: Int, configurationCount: Int) {
        self.init(device: device, atomCounts: [atomCount], configurationCounts: [configurationCount])
    }
    
    init?(device: MTLDevice, atomCounts: [Int], configurationCounts: [Int]) {

        var totalAtomCount = 0
        for (atomCount, configurationCount) in zip(atomCounts, configurationCounts) {
            totalAtomCount += atomCount * configurationCount
        }
        
        // Atom world center buffer
        guard let newAtomWorldCenterBuffer = device.makeBuffer(length: totalAtomCount * MemoryLayout<simd_float3>.stride,
                                                               options: .storageModePrivate) else {
            return nil
        }
        atomWorldCenterBuffer = newAtomWorldCenterBuffer
        
        // Atom radius buffer
        guard let newAtomRadiusBuffer = device.makeBuffer(length: totalAtomCount * MemoryLayout<Int16>.stride,
                                                          options: .storageModePrivate) else {
            return nil
        }
        atomRadiusBuffer = newAtomRadiusBuffer
    }
}
