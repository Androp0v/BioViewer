//
//  MatrixTransform.swift
//  BioViewer
//
//  Imported by Raúl Montón Pinillos on 1/6/21.
//

// swiftlint:disable all

import Foundation
import simd

// MARK: - Transform Utilities
enum Transform {

    /// A 4x4 translation matrix specified by x, y, and z components.
    static func translationMatrix(_ translation: SIMD3<Float>) -> simd_float4x4 {
        let col0 = SIMD4<Float>(1, 0, 0, 0)
        let col1 = SIMD4<Float>(0, 1, 0, 0)
        let col2 = SIMD4<Float>(0, 0, 1, 0)
        let col3 = SIMD4<Float>(translation, 1)
        return .init(col0, col1, col2, col3)
    }
    
    // A 4x4 rotation matrix from a quaternion.
    static func rotationMatrix(quaternion q: simd_quatd) -> simd_float4x4 {
        let q = simd_float4(q.vector)
        let xx = q.x * q.x;
        let xy = q.x * q.y;
        let xz = q.x * q.z;
        let xw = q.x * q.w;
        let yy = q.y * q.y;
        let yz = q.y * q.z;
        let yw = q.y * q.w;
        let zz = q.z * q.z;
        let zw = q.z * q.w;

        // indices are m<column><row>
        let m00: Float = 1 - 2 * (yy + zz)
        let m10: Float = 2 * (xy - zw)
        let m20: Float = 2 * (xz + yw)
        let m30: Float = 0.0

        let m01: Float = 2 * (xy + zw)
        let m11: Float = 1 - 2 * (xx + zz)
        let m21: Float = 2 * (yz - xw)
        let m31: Float = 0.0

        let m02: Float = 2 * (xz - yw)
        let m12: Float = 2 * (yz + xw)
        let m22: Float = 1 - 2 * (xx + yy)
        let m32: Float = 0.0
        
        let m03: Float = 0.0
        let m13: Float = 0.0
        let m23: Float = 0.0
        let m33: Float = 1.0

        return matrix_from_rows(
            simd_float4(m00, m10, m20, m30),
            simd_float4(m01, m11, m21, m31),
            simd_float4(m02, m12, m22, m32),
            simd_float4(m03, m13, m23, m33)
        )
    }

    /// A 4x4 rotation matrix specified by an angle and an axis or rotation.
    static func rotationMatrix(radians: Float, axis: SIMD3<Float>, around pivot: SIMD3<Float> = .zero) -> simd_float4x4 {
        let normalizedAxis = simd_normalize(axis)

        let ct = cosf(radians)
        let st = sinf(radians)
        let ci = 1 - ct
        let x = normalizedAxis.x
        let y = normalizedAxis.y
        let z = normalizedAxis.z
        let px = pivot.x
        let py = pivot.y
        let pz = pivot.z

        let col0 = SIMD4<Float>(
            ct + x * x * ci,
            y * x * ci + z * st,
            z * x * ci - y * st,
            0
        )
        let col1 = SIMD4<Float>(
            x * y * ci - z * st,
            ct + y * y * ci,
            z * y * ci + x * st,
            0
        )
        let col2 = SIMD4<Float>(
            x * z * ci + y * st,
            y * z * ci - x * st,
            ct + z * z * ci,
            0
        )
        let col3 = SIMD4<Float>(
            px - (ct + x * x * ci) * px - (x * y * ci - z * st) * py - (x * z * ci + y * st) * pz,
            py - (y * x * ci + z * st) * px - (ct + y * y * ci) * py - (y * z * ci - x * st) * pz,
            pz - (z * x * ci - y * st) * px - (z * y * ci + x * st) * py - (ct + z * z * ci) * pz,
            1
        )

        return .init(col0, col1, col2, col3)
    }
    
    /// A 4x4 rotation matrix specified by an angle and an axis or rotation.
    // FIXME: Ensure this is correct!!
    static func leftHandedRotationMatrix(radians: Float, axis: SIMD3<Float>, around pivot: SIMD3<Float> = .zero) -> simd_float4x4 {
        let normalizedAxis = simd_normalize(axis)

        let ct = cosf(radians)
        let st = sinf(radians)
        let ci = 1 - ct
        let x = normalizedAxis.x
        let y = normalizedAxis.y
        let z = normalizedAxis.z
        let px = pivot.x
        let py = pivot.y
        let pz = pivot.z

        let col0 = SIMD4<Float>(
            ct + x * x * ci,
            z * x * ci - y * st,
            y * x * ci + z * st,
            0
        )
        let col1 = SIMD4<Float>(
            x * y * ci - z * st,
            z * y * ci + x * st,
            ct + y * y * ci,
            0
        )
        let col2 = SIMD4<Float>(
            x * z * ci + y * st,
            ct + z * z * ci,
            y * z * ci - x * st,
            0
        )
        let col3 = SIMD4<Float>(
            px - (ct + x * x * ci) * px - (x * y * ci - z * st) * py - (x * z * ci + y * st) * pz,
            pz - (z * x * ci - y * st) * px - (z * y * ci + x * st) * py - (ct + z * z * ci) * pz,
            py - (y * x * ci + z * st) * px - (ct + y * y * ci) * py - (y * z * ci - x * st) * pz,
            1
        )

        return .init(col0, col1, col2, col3)
    }

    /// A 4x4 uniform scale matrix specified by x, y, and z components.
    static func scaleMatrix(_ scale: SIMD3<Float>) -> simd_float4x4 {
        let col0 = SIMD4<Float>(scale.x, 0, 0, 0)
        let col1 = SIMD4<Float>(0, scale.y, 0, 0)
        let col2 = SIMD4<Float>(0, 0, scale.z, 0)
        let col3 = SIMD4<Float>(0, 0, 0, 1)

        return .init(col0, col1, col2, col3)
    }

    /// Returns a 3x3 normal matrix from a 4x4 model matrix
    static func normalMatrix(from modelMatrix: simd_float4x4) -> simd_float3x3 {
        let col0 = modelMatrix.columns.0.xyz
        let col1 = modelMatrix.columns.1.xyz
        let col2 = modelMatrix.columns.2.xyz
        return .init(col0, col1, col2)
    }

    /// A left-handed orthographic projection
    static func orthographicProjection(_ left: Float,
                                       _ right: Float,
                                       _ bottom: Float,
                                       _ top: Float,
                                       _ nearZ: Float,
                                       _ farZ: Float) -> simd_float4x4 {

        let col0 = SIMD4<Float>(2 / (right - left), 0, 0, 0)
        let col1 = SIMD4<Float>(0, 2 / (top - bottom), 0, 0)
        let col2 = SIMD4<Float>(0, 0, 1 / (farZ - nearZ), 0)
        let col3 = SIMD4<Float>((left + right) / (left - right), (top + bottom) / (bottom - top), nearZ / (nearZ - farZ), 1)
        return .init(col0, col1, col2, col3)
    }

    /// A left-handed perspective projection
    static func perspectiveProjection(_ fovyRadians: Float,
                                      _ aspectRatio: Float,
                                      _ nearZ: Float,
                                      _ farZ: Float) -> simd_float4x4 {
        let ys = 1 / tanf(fovyRadians * 0.5)
        let xs = ys / aspectRatio
        let zs = farZ / (farZ - nearZ)

        let col0 = SIMD4<Float>(xs, 0, 0, 0)
        let col1 = SIMD4<Float>(0, ys, 0, 0)
        let col2 = SIMD4<Float>(0, 0, zs, 1)
        let col3 = SIMD4<Float>(0, 0, -nearZ * zs, 0)

        return .init(col0, col1, col2, col3)
    }

    /// Returns a left-handed matrix which looks from a point (the "eye") at a target point, given the up vector.
    static func look(eye: SIMD3<Float>, target: SIMD3<Float>, up: SIMD3<Float>) -> simd_float4x4 {

        let z = normalize(target - eye)
        let x = normalize(cross(up, z))
        let y = cross(z, x)
        let t = SIMD3<Float>(-dot(x, eye), -dot(y, eye), -dot(z, eye))

        let col0 = SIMD4<Float>(x.x, y.x, z.x, 0)
        let col1 = SIMD4<Float>(x.y, y.y, z.y, 0)
        let col2 = SIMD4<Float>(x.z, y.z, z.z, 0)
        let col3 = SIMD4<Float>(t.x, t.y, t.z, 1)

        return .init(col0, col1, col2, col3)
    }

}
