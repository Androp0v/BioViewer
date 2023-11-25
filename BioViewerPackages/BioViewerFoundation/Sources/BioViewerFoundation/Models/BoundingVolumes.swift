//
//  BoundingVolumes.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 7/12/21.
//

import Foundation
import simd

public struct BoundingSphere: Sendable {
    public let center: simd_float3
    public let radius: Float
}

public struct BoundingBox: Sendable {
    public let minX: Float
    public let maxX: Float
    public let minY: Float
    public let maxY: Float
    public let minZ: Float
    public let maxZ: Float
}

public struct BoundingVolume: Sendable {
    public let sphere: BoundingSphere
    public let box: BoundingBox
    
    public static var zero: Self {
        return BoundingVolume(
            sphere: BoundingSphere(center: .zero, radius: .zero),
            box: BoundingBox(minX: .zero, maxX: .zero, minY: .zero, maxY: .zero, minZ: .zero, maxZ: .zero)
        )
    }
}
