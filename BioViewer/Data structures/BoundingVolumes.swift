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
