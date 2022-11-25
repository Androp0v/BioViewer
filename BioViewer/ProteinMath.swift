//
//  ProteinMath.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 7/5/21.
//

import Foundation
import simd

// MARK: - Model normalization

func averagePosition(atoms: ContiguousArray<simd_float3>) -> simd_float3 {
    var meanPosition = simd_float3.zero
    atoms.forEach({
        meanPosition += $0
    })
    return meanPosition / Float(atoms.count)
}

func normalizeAtomPositions(atoms: inout ContiguousArray<simd_float3>, center: simd_float3) {
    for i in 0..<atoms.count {
        atoms[i] -= center
    }
}

// MARK: - Bounding volumes

/// Returns the approximate bounding sphere of a set of points, with an extra margin.
/// - Parameters:
///   - atoms: The positions of the atom centers.
///   - extraMargin: Safety margin to account for the radii of the atoms.
/// - Returns: Position of the center of the bounding sphere and its radius.
func computeBoundingSphere(atoms: ContiguousArray<simd_float3>, extraMargin: Float = 5) -> BoundingSphere {
    
    guard atoms.count != 1 else {
        return BoundingSphere(center: atoms.first!, radius: extraMargin)
    }
    
    let boundingBox = computeBoundingBox(atoms: atoms)
    let center: simd_float3 = simd_float3(x: (boundingBox.minX + boundingBox.maxX) / 2,
                                          y: (boundingBox.minY + boundingBox.maxY) / 2,
                                          z: (boundingBox.minZ + boundingBox.maxZ) / 2)
    
    // Compute box dimensions
    let length = boundingBox.maxX - boundingBox.minX
    let width = boundingBox.maxY - boundingBox.minY
    let depth = boundingBox.maxZ - boundingBox.minZ
    
    let radius = sqrt( pow(length, 2) + pow(width, 2) + pow(depth, 2) ) / 2
    
    return BoundingSphere(center: center, radius: radius + extraMargin)
}

func computeBoundingSphere(proteins: [Protein], extraMargin: Float = 5) -> BoundingSphere {
    var allAtoms = ContiguousArray<simd_float3>()
    for protein in proteins {
        allAtoms.append(contentsOf: protein.atoms)
    }
    return computeBoundingSphere(atoms: allAtoms, extraMargin: extraMargin)
}

func computeBoundingBox(atoms: ContiguousArray<simd_float3>) -> BoundingBox {
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
        }
        if x < minX {
            minX = x
        }
        if y > maxY {
            maxY = y
        }
        if y < minY {
            minY = y
        }
        if z > maxZ {
            maxZ = z
        }
        if z < minZ {
            minZ = z
        }
    }
    return BoundingBox(minX: minX, maxX: maxX, minY: minY, maxY: maxY, minZ: minZ, maxZ: maxZ)
}
