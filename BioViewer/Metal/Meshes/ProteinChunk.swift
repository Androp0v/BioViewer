//
//  ProteinChunk.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 31/5/21.
//

import Foundation
import simd

struct ProteinChunk {

    // Vertices of all the triangles in the chunk
    var vertices: [simd_float3]

    // Indices are used to construct triangles from the vertices
    // UInt16 has a max value of 65535 to we must not have more
    // than 21845 triangles in our chunk.
    var indices: [UInt16]
}
