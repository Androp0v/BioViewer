//
//  Ray.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 24/2/24.
//

import Foundation
import simd

struct Ray {
    let origin: simd_float3
    let direction: simd_float3
    
    static func *(transform: float4x4, ray: Ray) -> Ray {
        let originT = (transform * simd_float4(ray.origin, 1)).xyz
        let directionT = (transform * simd_float4(ray.direction, 0)).xyz
        return Ray(origin: originT, direction: directionT)
    }
    
    /// Determine the point along this ray at the given parameter
    func extrapolate(_ parameter: Float) -> simd_float4 {
        return simd_float4(origin + parameter * direction, 1)
    }
    
    /// Determine the parameter corresponding to the point,
    /// assuming it lies on this ray
    func interpolate(_ point: simd_float4) -> Float {
        return length(point.xyz - origin) / length(direction)
    }
}
