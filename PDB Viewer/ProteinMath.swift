//
//  ProteinMath.swift
//  PDB Viewer
//
//  Created by Raúl Montón Pinillos on 7/5/21.
//

import Foundation
import simd

func averagePosition(atoms: [simd_float3]) -> simd_float3 {
    var meanPosition = simd_float3(0,0,0)
    atoms.forEach({
        meanPosition += $0
    })
    return meanPosition / Float(atoms.count)
}

func normalizeAtomPositions(atoms: inout [simd_float3]) {
    let averagePosition = averagePosition(atoms: atoms)
    for i in 0..<atoms.count {
        atoms[i] -= averagePosition
    }
}
