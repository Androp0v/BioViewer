//
//  BoundingVolumes.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 7/12/21.
//

import Foundation

public struct BoundingSphere {
    let center: simd_float3
    let radius: Float
}

public struct BoundingBox {
    let minX: Float
    let maxX: Float
    let minY: Float
    let maxY: Float
    let minZ: Float
    let maxZ: Float
}
