//
//  MetalScene.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 17/10/21.
//

import Combine
import CoreGraphics
import Foundation
import simd
import SwiftUI

class MetalScene {
    
    // MARK: - Properties
        
    /// Whether the scene needs to be redrawn for the next frame.
    var needsRedraw: Bool = false
    
    /// The last time a color buffer recompute was required.
    var lastColorPassRequest: CFTimeInterval = CACurrentMediaTime()
    /// The last time a color buffer recompute was performed.
    var lastColorPass: CFTimeInterval = .zero
    
    /// Whether the scene is playing (a configuration loop, or a rotation, for example). If true, overrides ```needsRedraw```.
    var isPlaying: Bool = false
    /// Class used to animate changes in scene properties.
    var animator: SceneAnimator?
    
    /// Struct with data passed to the GPU shader that can be modified between draw calls.
    private var frameData: FrameData
    /// Struct with data passed to the GPU shader for the current frame. Only updated on draw calls.
    var currentFrameData: FrameData
    /// Struct with data passed to the GPU shader for the last frame. Only updated on draw calls.
    var lastFrameFrameData: FrameData?
    /// Current atom radii configuration
    var atom_radii: AtomRadii
    /// Frame count since the scene started.
    var frame: Int
    
    /// Object to select the appropriate regions of the MTLBuffer for each protein configuration.
    var configurationSelector: ConfigurationSelector?
    
    /// Sun position, world coordinates.
    var sunDirection = SunDirection()
    
    // MARK: - Representation properties
    /// Current ProteinVisualizationOption. May not match the value of the ProteinViewModel `visualization` until the new geometry
    /// is generated and the buffers are populated.
    var currentVisualization: ProteinVisualizationOption = .ballAndStick { didSet { needsRedraw = true } }
    
    // MARK: - Camera properties
    
    /// Camera used to render the scene.
    private(set) var camera: Camera
    /// Position of the camera used to render the scene.
    private(set) var cameraPosition: simd_float3 { didSet { needsRedraw = true } }
    /// Bounding sphere of the visualised data.
    var boundingSphere = BoundingSphere(center: .zero, radius: .zero)
    /// Rotation of the model applied by the user.
    var userModelRotationMatrix: simd_float4x4 { didSet { needsRedraw = true } }
    /// Scene's aspect ratio, determined by the MTKView it's displayed on.
    var aspectRatio: Float { didSet { needsRedraw = true } }
    /// Subscriber to camera changes.
    var cameraChangedCancellable: AnyCancellable?
    /// Whether the camera is autorotating.
    var autorotating: Bool = false { didSet { needsRedraw = true } }
    
    // MARK: - Shadow properties

    /// Whether shadows should be casted between geometry elements.
    var hasShadows: Bool { didSet { needsRedraw = true } }
    var shadowStrength: Float = 0.4 { didSet { needsRedraw = true } }
    /// Whether depth cueing should be used in the scene.
    var hasDepthCueing: Bool { didSet { needsRedraw = true } }
    var depthCueingStrength: Float = 0.3 { didSet { needsRedraw = true } }
    
    // MARK: - Color properties
    
    /// Background color of the view.
    var backgroundColor: CGColor { didSet { needsRedraw = true } }
    /// Color used for bonds in ball and sticks mode.
    var bondColor: CGColor {
        didSet {
            if let components = bondColor.components {
                frameData.bond_color = simd_float3(
                    Float(components[0]),
                    Float(components[1]),
                    Float(components[2])
                )
            }
            needsRedraw = true
        }
    }
    /// What kind of color scheme is used to color atoms (i.e. by element or by chain).
    var colorFill = FillColorInput() {
        didSet {
            lastColorPassRequest = CACurrentMediaTime()
            needsRedraw = true
        }
    }
    
    // MARK: - Initialization

    init() {
        self.camera = Camera(nearPlane: 1, farPlane: 10000, focalLength: 200)
        self.cameraPosition = simd_float3(0, 0, 1000)
        self.userModelRotationMatrix = Transform.scaleMatrix(.one)
        self.backgroundColor = .init(red: .zero, green: .zero, blue: .zero, alpha: 1.0)
        self.bondColor = .init(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        self.frameData = FrameData()
        self.frame = 0
        self.aspectRatio = 1.0

        // Setup initial values for FrameData
        self.frameData.model_view_matrix = Transform.translationMatrix(self.cameraPosition)
        self.frameData.projectionMatrix = self.camera.projectionMatrix
                
        if AppState.hasSamplerCompareSupport() {
            self.hasShadows = true
        } else {
            self.hasShadows = false
        }
        self.hasDepthCueing = false
        
        // Initial atom radii
        self.atom_radii = AtomRadiiGenerator.vanDerWaalsRadii()
        
        self.frameData.shadow_strength = shadowStrength
        self.frameData.depth_cueing_strength = depthCueingStrength
        
        // Initial currentFrameData
        self.currentFrameData = frameData
        
        // Subscribe to changes in the camera properties
        cameraChangedCancellable = self.camera.didChange.sink(receiveValue: { [weak self] _ in
            guard let self = self else { return }
            self.needsRedraw = true
        })
        
        // Initial rotation matrix values
        updateModelRotation(rotationMatrix: Transform.rotationMatrix(
            radians: 0.0,
            axis: simd_float3(0.0, 1.0, 0.0)
        ))
        
        // Set initial sun direction
        setSunDirection(theta: sunDirection.theta, phi: sunDirection.phi) 
        
        // Set initial FrameData bond color
        if let components = bondColor.components {
            self.frameData.bond_color = simd_float3(
                Float(components[0]),
                Float(components[1]),
                Float(components[2])
            )
        }
        
        // Pass cast shadows and depth cueing to FrameData
        self.frameData.has_shadows = self.hasShadows ? 1 : 0
        self.frameData.has_depth_cueing = self.hasDepthCueing ? 1 : 0
            
        // Create the animator
        self.animator = SceneAnimator(scene: self)
    }

    // MARK: - Update scene

    func updateScene() {
        guard needsRedraw || isPlaying else { return skipFrame() }
        // Update last frame's frame data
        self.lastFrameFrameData = currentFrameData
        self.camera.updateProjection(aspectRatio: aspectRatio)
        self.frameData.model_view_matrix = Transform.translationMatrix(cameraPosition)
        self.frameData.projectionMatrix = self.camera.projectionMatrix
        
        // Update configuration
        if isPlaying {
            if frame % 1 == 0 {
                self.configurationSelector?.nextConfiguration()
            }
        }
        
        // Update rotation matrices
        if !autorotating {
            updateModelRotation(rotationMatrix: self.userModelRotationMatrix)
        }
        
        // Update shadow behaviour
        self.frameData.has_shadows = self.hasShadows ? 1 : 0
        self.frameData.shadow_strength = self.shadowStrength
        self.frameData.has_depth_cueing = self.hasDepthCueing ? 1 : 0
        self.frameData.depth_cueing_strength = self.depthCueingStrength
        
        frame += 1
        needsRedraw = false
        
        // Autorotation
        if autorotating {
            let autorotationMatrix = Transform.rotationMatrix(
                radians: -0.001,
                axis: (self.userModelRotationMatrix.inverse * simd_float4(0, 1, 0, 1)).xyz
            )
            self.userModelRotationMatrix *= autorotationMatrix
            updateModelRotation(rotationMatrix: self.userModelRotationMatrix)
            needsRedraw = true
        }
        // Store current frame data
        self.currentFrameData = frameData
    }
    
    // MARK: - Sun direction
    
    func setSunDirection(theta: Angle, phi: Angle) {
        let x = Float(cos(phi.radians) * sin(theta.radians))
        let y = Float(sin(phi.radians))
        let z = -Float(cos(phi.radians) * cos(theta.radians))
        self.sunDirection = SunDirection(theta: theta, phi: phi)
        self.frameData.sun_direction = normalize(simd_float3(x: x, y: y, z: z))
    }
    
    // MARK: - Update rotation
    
    private func updateModelRotation(rotationMatrix: simd_float4x4) {
        
        self.userModelRotationMatrix = rotationMatrix
        let translateToOriginMatrix = Transform.translationMatrix(-boundingSphere.center)

        // Update model rotation matrix
        self.frameData.rotation_matrix = rotationMatrix * translateToOriginMatrix
        self.frameData.inverse_rotation_matrix = rotationMatrix.inverse
        
        // Update sun rotation matrix (model rotation + sun rotation)
        let phiRotation = Transform.leftHandedRotationMatrix(
            radians: Float(sunDirection.phi.radians),
            axis: simd_float3(-1.0, 0.0, 0.0)
        )
        let originalYDirection = phiRotation.inverse * simd_float4(0.0, -1.0, 0.0, 1.0)
        let thetaRotation = Transform.leftHandedRotationMatrix(
            radians: Float(sunDirection.theta.radians),
            axis: originalYDirection.xyz
        )
        let sunRotation = thetaRotation * phiRotation
        self.frameData.sun_rotation_matrix = sunRotation * rotationMatrix * translateToOriginMatrix
        
        // Update camera -> sun's coordinate transform
        self.frameData.camera_to_shadow_projection_matrix = self.frameData.shadowProjectionMatrix
            * sunRotation
            * Transform.translationMatrix(cameraPosition).inverse
    }
        
    // MARK: - Fit protein on screen
    
    func updateCameraDistanceToModel(distanceToModel: Float, proteinDataSource: ProteinDataSource) {
        // TO-DO: Fit all files
        self.boundingSphere = proteinDataSource.selectionBoundingSphere
        
        // Update camera far and near planes
        self.camera.nearPlane = max(1, distanceToModel - boundingSphere.radius)
        self.camera.farPlane = distanceToModel + boundingSphere.radius
        // Update camera z-position
        self.cameraPosition.z = distanceToModel
        
        // Update frameData's depth bias.
        let armstrongsInBoundingSphere = camera.farPlane - camera.nearPlane
        self.frameData.depth_bias = 2 / armstrongsInBoundingSphere
        
        // Update shadow projection to fit too
        self.frameData.shadowProjectionMatrix = Transform.orthographicProjection(
            -boundingSphere.radius + 3.3,
             boundingSphere.radius - 3.3,
             -boundingSphere.radius + 3.3,
             boundingSphere.radius - 3.3,
             -boundingSphere.radius - 3.3,
             boundingSphere.radius + 3.3
        )
    }
    
    // MARK: - Reprojection
    
    func reprojectionData(currentFrameData: FrameData, oldFrameData: FrameData?) -> ReprojectionData? {
        guard let oldFrameData else { return nil }
        // Unproject from NDC to camera coordinates
        var reprojectionMatrix = currentFrameData.projectionMatrix.inverse
        // Unproject to world coordinates (rotated)
        reprojectionMatrix = currentFrameData.model_view_matrix.inverse * reprojectionMatrix
        // Unrotate to world coordinates (original)
        reprojectionMatrix = currentFrameData.rotation_matrix.inverse * reprojectionMatrix
        // Rotate to old world coordinates (rotated)
        reprojectionMatrix = oldFrameData.rotation_matrix * reprojectionMatrix
        // Project to old camera coordinates
        reprojectionMatrix = oldFrameData.model_view_matrix * reprojectionMatrix
        // Project to old NDC
        reprojectionMatrix = oldFrameData.projectionMatrix * reprojectionMatrix
        // Nice! We have a matrix that transforms current-frame NDC to last-frame's NDC.
        return ReprojectionData(reprojection_matrix: reprojectionMatrix)
    }
    
    // MARK: - Move camera
    
    func translateCamera(x: Float, y: Float) {
        self.cameraPosition.x += x
        self.cameraPosition.y += y
    }
    
    func resetCamera() {
        // Undo translation
        self.cameraPosition.x = 0
        self.cameraPosition.y = 0
        // Undo rotation
        updateModelRotation(rotationMatrix: Transform.scaleMatrix(.one))
        // TO-DO: Undo zoom
    }
    
    // MARK: - Private
    
    private func skipFrame() {
        frame += 1
    }
}
