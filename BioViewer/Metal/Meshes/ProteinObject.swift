//
//  ProteinObject.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 31/5/21.
//

import Foundation

// MARK: - ProteinObject

// Struct grouping all the chunks (sub-meshes) of a single protein, and
// how it's dividided into chunks.
class ProteinObject {
    
    let gridCount = 3
    var chunks = [ProteinChunk]()
    var boundingBox: (simd_float2, simd_float2, simd_float2)?
    
    public func computeChunkID(position: simd_float3) -> Int {
        // TO-DO
        return 0
    }
    
    init(protein: Protein) {
        // TO-DO: Split a whole Protein into chunks
        // Compute bounding box
        // Assign atoms into chunks
    }

}
