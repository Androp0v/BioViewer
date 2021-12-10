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

class MetalScene: ObservableObject {

    // MARK: - Properties
    
    /// Whether the scene needs to be redrawn for the next frame.
    var needsRedraw: Bool = false
    
    /// Struct with data passed to the GPU shader.
    var frameData: FrameData
    /// Frame count since the scene started.
    var frame: Int
    
    /// Sun position, world coordinates.
    var sunDirection: simd_float3 = simd_float3(1, 1, 0)
    
    // MARK: - Camera properties
    
    /// Camera used to render the scene.
    private(set) var camera: Camera
    /// Position of the camera used to render the scene.
    private(set) var cameraPosition: simd_float3 { didSet { needsRedraw = true } }
    /// Rotation of the model applied by the user.
    var userModelRotationMatrix: simd_float4x4 { didSet { needsRedraw = true} }
    /// Scene's aspect ratio, determined by the MTKView it's displayed on.
    var aspectRatio: Float { didSet { needsRedraw = true } }
    /// Subscriber to camera changes.
    var cameraChangedCancellable: AnyCancellable?
    
    // MARK: - Shadow properties
    
    /// Whether shadows should be casted between geometry elements.
    @Published var hasShadows: Bool { didSet { needsRedraw = true } }
    @Published var shadowStrength: Float = 0.3 { didSet { needsRedraw = true } }
    /// Whether depth cueing should be used in the scene.
    @Published var hasDepthCueing: Bool { didSet { needsRedraw = true } }
    
    // MARK: - Color properties
    
    /// Background color of the view.
    var backgroundColor: CGColor { didSet { needsRedraw = true } }
    /// What kind of color scheme is used to color atoms (i.e. by element or by chain).
    @Published var colorBy: Int {
        didSet {
            if colorBy == ProteinColorByOption.element {
                self.frameData.colorBySubunit = 0 // False
            } else {
                self.frameData.colorBySubunit = 1 // True
            }
            needsRedraw = true
        }
    }
        
    @Published var cAtomColor: Color = Color(.displayP3, red: 0.423, green: 0.733, blue: 0.235, opacity: 1.0) {
        didSet { needsRedraw = true }
    }
    
    @Published var hAtomColor: Color = Color(.displayP3, red: 0.517, green: 0.517, blue: 0.517, opacity: 1.0) {
        didSet { needsRedraw = true }
    }
    
    @Published var nAtomColor: Color = Color(.displayP3, red: 0.091, green: 0.148, blue: 0.556, opacity: 1.0) {
        didSet { needsRedraw = true }
    }
    
    @Published var oAtomColor: Color = Color(.displayP3, red: 1.000, green: 0.149, blue: 0.000, opacity: 1.0) {
        didSet { needsRedraw = true }
    }
    
    @Published var sAtomColor: Color = Color(.displayP3, red: 1.000, green: 0.780, blue: 0.349, opacity: 1.0) {
        didSet { needsRedraw = true }
    }
    
    @Published var unknownAtomColor: Color = Color(.displayP3, red: 0.517, green: 0.517, blue: 0.517, opacity: 1.0) {
        didSet { needsRedraw = true }
    }
    
    @Published var subunitColors: [Color] = [Color]() {
        didSet { needsRedraw = true }
    }

    // MARK: - Initialization

    init() {
        self.camera = Camera(nearPlane: 1, farPlane: 10000, focalLength: 200)
        self.cameraPosition = simd_float3(0, 0, 1000)
        self.userModelRotationMatrix = Transform.rotationMatrix(radians: 0, axis: simd_float3(0, 1, 0))
        self.backgroundColor = .init(red: .zero, green: .zero, blue: .zero, alpha: 1.0)
        self.frameData = FrameData()
        self.frame = 0
        self.aspectRatio = 1.0

        // Setup initial values for FrameData
        self.frameData.model_view_matrix = Transform.translationMatrix(self.cameraPosition)
        self.frameData.inverse_model_view_matrix = Transform.translationMatrix(cameraPosition).inverse
        self.frameData.projectionMatrix = self.camera.projectionMatrix
        self.frameData.rotation_matrix = Transform.rotationMatrix(radians: 0.0,
                                                                  axis: simd_float3(0.0, 1.0, 0.0))
        self.frameData.inverse_rotation_matrix = Transform.rotationMatrix(radians: 0.0,
                                                                          axis: simd_float3(0.0, 1.0, 0.0)).inverse
        
        self.frameData.shadowProjectionMatrix = Transform.orthographicProjection(-200, 200, -200, 200, -200, 200)
        self.frameData.sunRotationMatrix = Transform.rotationMatrix(radians: Float.pi / 2,
                                                                    axis: simd_float3(-1.0, 0.0, 1.0))
        self.frameData.inverseSunRotationMatrix = Transform.rotationMatrix(radians: Float.pi / 2,
                                                                           axis: simd_float3(-1.0, 0.0, 1.0)).inverse
        
        self.frameData.colorBySubunit = 0 // False, color by atom element
        self.colorBy = ProteinColorByOption.element
        
        if AppState.hasSamplerCompareSupport() {
            self.hasShadows = true
        } else {
            self.hasShadows = false
        }
        self.hasDepthCueing = false
        
        self.frameData.shadow_strength = shadowStrength

        // Subscribe to changes in the camera properties
        cameraChangedCancellable = self.camera.didChange.sink(receiveValue: { [weak self] _ in
            guard let self = self else { return }
            self.needsRedraw = true
        })
        
        // Pass cast shadows and depth cueing to FrameData
        self.frameData.has_shadows = self.hasShadows ? 1 : 0
        self.frameData.has_depth_cueing = self.hasDepthCueing ? 1 : 0
        
        // TO-DO: This is not very elegant
        self.frameData.atomRadius.0 = 1.70 // Carbon
        self.frameData.atomRadius.1 = 1.55 // Nitrogen
        self.frameData.atomRadius.2 = 1.52 // Hydrogen
        self.frameData.atomRadius.3 = 1.80 // Oxygen
        self.frameData.atomRadius.4 = 1.10 // Sulfur
        self.frameData.atomRadius.5 = 1.0 // Others
        
        self.frameData.atomColor.0 = simd_float4(0.423, 0.733, 0.235, 1.0) // Carbon
        self.frameData.atomColor.1 = simd_float4(0.091, 0.148, 0.556, 1.0) // Nitrogen
        self.frameData.atomColor.2 = simd_float4(0.517, 0.517, 0.517, 1.0) // Hydrogen
        self.frameData.atomColor.3 = simd_float4(1.000, 0.149, 0.000, 1.0) // Oxygen
        self.frameData.atomColor.4 = simd_float4(1.000, 0.780, 0.349, 1.0) // Sulfur
        self.frameData.atomColor.5 = simd_float4(0.517, 0.517, 0.517, 1.0) // Others
        
        initSubunitColors()
    }

    // MARK: - Updates

    func updateScene() {
        guard needsRedraw else { return skipFrame() }
        self.camera.updateProjection(aspectRatio: aspectRatio)
        self.frameData.model_view_matrix = Transform.translationMatrix(cameraPosition)
        self.frameData.inverse_model_view_matrix = Transform.translationMatrix(cameraPosition).inverse
        self.frameData.projectionMatrix = self.camera.projectionMatrix
        self.frameData.rotation_matrix = self.userModelRotationMatrix
        self.frameData.inverse_rotation_matrix = self.frameData.rotation_matrix.inverse
        
        // Update shadow behaviour
        self.frameData.has_shadows = self.hasShadows ? 1 : 0
        self.frameData.shadow_strength = self.shadowStrength
        self.frameData.has_depth_cueing = self.hasDepthCueing ? 1 : 0
        
        updateColors()
        frame += 1
        needsRedraw = false
        
        // TO-DO
        /*self.frameData.rotation_matrix = Transform.rotationMatrix(radians: -0.001 * Float(frame),
                                                                  axis: simd_float3(0,1,0))
        self.frameData.inverse_rotation_matrix = self.frameData.rotation_matrix.inverse
        needsRedraw = true*/
    }
    
    func updateCameraDistanceToModel(distanceToModel: Float, proteinDataSource: ProteinViewDataSource) {
        // TO-DO: Fit all files
        guard let protein = proteinDataSource.files.first?.protein else {
            return
        }
        // Update camera far and near planes
        self.camera.nearPlane = max(1, distanceToModel - protein.boundingSphere.radius)
        self.camera.farPlane = distanceToModel + protein.boundingSphere.radius
        // Update camera position
        self.cameraPosition = simd_float3(0, 0, distanceToModel)
        
        // Update shadow projection to fit too
        let boundingSphereRadius = protein.boundingSphere.radius
        self.frameData.shadowProjectionMatrix = Transform.orthographicProjection(-boundingSphereRadius + 3.3,
                                                                                  boundingSphereRadius - 3.3,
                                                                                 -boundingSphereRadius + 3.3,
                                                                                  boundingSphereRadius - 3.3,
                                                                                 -distanceToModel - boundingSphereRadius + 3.3,
                                                                                  distanceToModel + boundingSphereRadius - 3.3)
    }
    
    // MARK: - Private
    
    private func skipFrame() {
        frame += 1
    }
}
