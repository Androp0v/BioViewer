//
//  ProteinMesh.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 31/5/21.
//

import Foundation

// MARK: - ProteinMesh
// Struct grouping all the chunks (sub-meshes) of a single protein, and
// how it's dividided into chunks.
struct ProteinMesh {

    var chunks = [ProteinChunk]()

    init() {
        // TO-DO: Split a whole Protein into chunks
    }

}
