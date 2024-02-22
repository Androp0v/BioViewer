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

/// The bounding volume of an object.
public struct BoundingVolume: Sendable {
    /// The bounding __sphere__ of the object.
    public let sphere: BoundingSphere
    /// The bounding __box__ of the object.
    public let box: BoundingBox
    
    /// A `BoundingVolume` that has no volume, centered at the origin.
    public static var zero: Self {
        return BoundingVolume(
            sphere: BoundingSphere(center: .zero, radius: .zero),
            box: BoundingBox(minX: .zero, maxX: .zero, minY: .zero, maxY: .zero, minZ: .zero, maxZ: .zero)
        )
    }
}
