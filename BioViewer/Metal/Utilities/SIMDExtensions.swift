//
//  SIMDExtensions.swift
//  BioViewer
//
//  Imported by Raúl Montón Pinillos on 1/6/21.
//

import Foundation

// MARK: - SIMD4
extension SIMD4 {
    // Convenience getter for the first 3 components of a SIMD4 vector.
    var xyz: SIMD3<Scalar> {
        self[SIMD3(0, 1, 2)]
    }
}

extension simd_quatf {
    static var identity: simd_quatf {
        return simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
    }
}

extension Float {
    static var randomSign: Float {
        if Bool.random() {
            return 1
        } else {
            return -1
        }
    }
}
