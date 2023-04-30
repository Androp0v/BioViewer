//
//  BoundingVolumes.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 7/12/21.
//

import Foundation

struct BoundingSphere: Sendable {
    let center: simd_float3
    let radius: Float
}

struct BoundingBox: Sendable {
    let minX: Float
    let maxX: Float
    let minY: Float
    let maxY: Float
    let minZ: Float
    let maxZ: Float
}

struct BoundingVolume: Sendable {
    let sphere: BoundingSphere
    let box: BoundingBox
    
    static var zero: Self {
        return BoundingVolume(
            sphere: BoundingSphere(center: .zero, radius: .zero),
            box: BoundingBox(minX: .zero, maxX: .zero, minY: .zero, maxY: .zero, minZ: .zero, maxZ: .zero)
        )
    }
}
