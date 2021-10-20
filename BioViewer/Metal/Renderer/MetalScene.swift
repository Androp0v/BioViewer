//
//  MetalScene.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 17/10/21.
//

import CoreGraphics
import Foundation
import simd

class MetalScene {

    // MARK: - Properties

    /// Camera used to render the scene
    var camera: Camera
    /// Position of the camera used to render the scene
    var cameraPosition: simd_float3
    /// Background color of the view
    var backgroundColor: CGColor
    /// Struct with data passed to the GPU shader
    var frameData: FrameData
    /// Frame count since the scene started
    var frame: Int

    // MARK: - Initialization

    init() {
        self.camera = Camera(nearPlane: 0.1, farPlane: 3000, fieldOfView: 85)
        self.cameraPosition = simd_float3(0, 0, 300)
        self.backgroundColor = .init(red: .zero, green: .zero, blue: .zero, alpha: 1.0)
        self.frameData = FrameData()
        self.frame = 0

        // Setup initial values for FrameData
        self.frameData.model_view_matrix = Transform.translationMatrix(self.cameraPosition)
        self.frameData.projectionMatrix = self.camera.projectionMatrix
        self.frameData.rotation_matrix = Transform.rotationMatrix(radians: Float.pi,
                                                                  axis: simd_float3(0.0, 1.0, 0.0))

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
    }

    // MARK: - Updates

    func update() {
        self.frameData.model_view_matrix = Transform.translationMatrix(cameraPosition)
        self.frameData.projectionMatrix = self.camera.projectionMatrix
        self.frameData.rotation_matrix = Transform.rotationMatrix(radians: -0.001 * Float(frame),
                                                                  axis: simd_float3(0,1,0))
        frame += 1
    }
}
