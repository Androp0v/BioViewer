//
//  Camera.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 3/6/21.
//

import CoreGraphics
import simd

fileprivate let fullFrameDiagonal: Float = 43.3 // mm

// MARK: - Camera

struct Camera {
    var nearPlane: Float
    var farPlane: Float
    var fieldOfView: Float
    var focalLength: Float
    var projectionMatrix = simd_float4x4()

    /// Initialize the camera struct.
    /// - Parameters:
    ///   - nearPlane: Closest plane in world coordinates.
    ///   - farPlane: Farthest plane in world coordinates.
    ///   - fieldOfView: Diagonal field of view of the camera, in degrees.
    init(nearPlane: Float, farPlane: Float, fieldOfView: Float) {
        self.nearPlane = nearPlane
        self.farPlane = farPlane
        self.fieldOfView = fieldOfView
        self.focalLength = fullFrameDiagonal / ( 2 * tan( (fieldOfView * Float.pi / 180) / 2 ) )
    }

    /// Initialize the camera struct.
    /// - Parameters:
    ///   - nearPlane: Closest plane in world coordinates.
    ///   - farPlane: Farthest plane in world coordinates.
    ///   - focalLength: Focal length of the camera, in mm, assuming a full frame sensor size.
    init(nearPlane: Float, farPlane: Float, focalLength: Float) {
        self.nearPlane = nearPlane
        self.farPlane = farPlane
        self.fieldOfView = 2 * atan( fullFrameDiagonal / (2 * focalLength) ) * 180 / Float.pi
        self.focalLength = focalLength
    }


    /// Update the projection matrix of the cammera to account for the aspect ratio of the drawable the
    /// view is displayed on.
    /// - Parameter drawableSize: The size of the view the scene is rendered on.
    mutating func updateProjection(drawableSize: CGSize) {
        let fieldOfViewRadians = fieldOfView * Float.pi / 180
        let aspectRatio = Float(drawableSize.width) / Float(drawableSize.height)
        projectionMatrix = Transform.perspectiveProjection(fieldOfViewRadians,
                                                           aspectRatio,
                                                           nearPlane,
                                                           farPlane)
    }
}
