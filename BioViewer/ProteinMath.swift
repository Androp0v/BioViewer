//
//  ProteinMath.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 7/5/21.
//

import Foundation
import simd

func averagePosition(atoms: ContiguousArray<simd_float3>) -> simd_float3 {
    var meanPosition = simd_float3(0,0,0)
    atoms.forEach({
        meanPosition += $0
    })
    return meanPosition / Float(atoms.count)
}

func normalizeAtomPositions(atoms: inout ContiguousArray<simd_float3>) {
    let averagePosition = averagePosition(atoms: atoms)
    for i in 0..<atoms.count {
        atoms[i] -= averagePosition
    }
}

func boundingBox(atoms: ContiguousArray<simd_float3>) -> (simd_float2, simd_float2, simd_float2) {
    var minX = Float32.infinity
    var maxX = -Float32.infinity
    var minY = Float32.infinity
    var maxY = -Float32.infinity
    var minZ = Float32.infinity
    var maxZ = -Float32.infinity
    for atom in atoms {
        let x = atom.x
        let y = atom.y
        let z = atom.z
        if x > maxX {
            maxX = x
        } else if x < minX {
            minX = x
        }
        if y > maxY {
            maxY = y
        } else if y < minY {
            minY = y
        }
        if z > maxZ {
            maxZ = z
        } else if z < minZ {
            minZ = z
        }
    }
    return (simd_float2(minX, maxX), simd_float2(minY, maxY), simd_float2(minZ, maxZ))
}
