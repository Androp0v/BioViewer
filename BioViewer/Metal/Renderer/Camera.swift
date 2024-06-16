//
//  Camera.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 3/6/21.
//

import Combine
import CoreGraphics
import simd

// MARK: - Camera

final class Camera {
    
    private static let fullFrameDiagonal: Float = 43.3 // mm
    
    /// Whether the camera has changed its properties
    @Published var didChange = PassthroughSubject<Bool, Never>()
    
    /// Near clipping plane of the camera view frustum.
    var nearPlane: Float
    /// Far clipping plane of the camera view frustum.
    var farPlane: Float
    /// Vertical field of view of the camera, in degrees. Related to focal length.
    var verticalFieldOfView: Float
    /// Focal length of the camera. Related to the vertical field of view.
    var focalLength: Float
    /// Projection matrix of the camera.
    var projectionMatrix = simd_float4x4()
    
    // MARK: - Initialization
    
    /// Initialize the camera struct.
    /// - Parameters:
    ///   - nearPlane: Closest plane in world coordinates.
    ///   - farPlane: Farthest plane in world coordinates.
    ///   - fieldOfView: Diagonal field of view of the camera, in degrees.
    init(nearPlane: Float, farPlane: Float, fieldOfView: Float) {
        self.nearPlane = nearPlane
        self.farPlane = farPlane
        self.verticalFieldOfView = fieldOfView
        self.focalLength = Camera.fullFrameDiagonal / ( 2 * tan( (fieldOfView * Float.pi / 180) / 2 ) )
        projectionMatrix = Transform.perspectiveProjection(
            fieldOfView * Float.pi / 180,
            1.0,
            nearPlane,
            farPlane
        )
    }

    /// Initialize the camera struct.
    /// - Parameters:
    ///   - nearPlane: Closest plane in world coordinates.
    ///   - farPlane: Farthest plane in world coordinates.
    ///   - focalLength: Focal length of the camera, in mm, assuming a full frame sensor size.
    init(nearPlane: Float, farPlane: Float, focalLength: Float) {
        self.nearPlane = nearPlane
        self.farPlane = farPlane
        self.verticalFieldOfView = 2 * atan( Camera.fullFrameDiagonal / (2 * focalLength) ) * 180 / Float.pi
        self.focalLength = focalLength
        projectionMatrix = Transform.perspectiveProjection(verticalFieldOfView * Float.pi / 180,
                                                           1.0,
                                                           nearPlane,
                                                           farPlane)
    }

    // MARK: - Updates
    
    /// Update the projection matrix of the camera to account for the aspect ratio of the drawable the
    /// view is displayed on.
    /// - Parameter drawableSize: The size of the view the scene is rendered on.
    func updateProjection(drawableSize: CGSize) {
        let fieldOfViewRadians = verticalFieldOfView * Float.pi / 180
        let aspectRatio = Float(drawableSize.width) / Float(drawableSize.height)
        projectionMatrix = Transform.perspectiveProjection(fieldOfViewRadians,
                                                           aspectRatio,
                                                           nearPlane,
                                                           farPlane)
        didChange.send(true)
    }
    
    /// Update the projection matrix of the cammera to account for the aspect ratio of the drawable the
    /// view is displayed on.
    /// - Parameter drawableSize: The size of the view the scene is rendered on.
    func updateProjection(aspectRatio: Float) {
        let fieldOfViewRadians = verticalFieldOfView * Float.pi / 180
        projectionMatrix = Transform.perspectiveProjection(fieldOfViewRadians,
                                                           aspectRatio,
                                                           nearPlane,
                                                           farPlane)
        didChange.send(true)
    }
    
    /// Update the projection matrix of the camera to account for the aspect ratio of the drawable the
    /// view is displayed on.
    /// - Parameter drawableSize: The size of the view the scene is rendered on.
    func updateFocalLength(focalLength: Float, aspectRatio: Float) {
        self.focalLength = focalLength
        self.verticalFieldOfView = 2 * atan( Camera.fullFrameDiagonal / (2 * focalLength) ) * 180 / Float.pi
        projectionMatrix = Transform.perspectiveProjection(verticalFieldOfView * Float.pi / 180,
                                                           aspectRatio,
                                                           nearPlane,
                                                           farPlane)
        didChange.send(true)
    }
    
    // MARK: - Functions
    
    func distanceToFitInFrustum(sphereRadius: Float, aspectRatio: Float) -> Float {
                
        let verticalFOV = verticalFieldOfView * Float.pi / 180
        let horizontalFOV = verticalFOV * aspectRatio
        let smallestFOV = min(verticalFOV, horizontalFOV)
        
        let distanceToFit = sphereRadius / sin(smallestFOV / 2)
        return distanceToFit
    }
}
