//
//  BondStruct.swift
//
//
//  Created by Raúl Montón Pinillos on 12/11/23.
//

import Foundation
import simd

public struct BondStruct {
    /// Position of the first atom in world space.
    public let atomA: simd_float3
    /// Position of the first atom in world space.
    public let atomB: simd_float3
    /// Cylinder center in world space.
    public let cylinderCenter: simd_float3
    /// Bond radius.
    public let bondRadius: Float
    
    public init(atomA: simd_float3, atomB: simd_float3, cylinderCenter: simd_float3, bondRadius: Float) {
        self.atomA = atomA
        self.atomB = atomB
        self.cylinderCenter = cylinderCenter
        self.bondRadius = bondRadius
    }
}
