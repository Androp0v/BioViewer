//
//  MakeBufferFromArray.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/5/22.
//

import Foundation
import Metal

extension ProteinRenderer {
    public func makeBufferFromArray<T>(array: [T]) -> MTLBuffer? {
        let arrayCopy = array
        let buffer = device.makeBuffer(
            bytes: arrayCopy,
            length: MemoryLayout<T>.stride * arrayCopy.count
        )
        return buffer
    }
}
