//
//  SelectionModel.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/2/24.
//

import Foundation
import SwiftUI

@MainActor @Observable class SelectionModel {
    
    private(set) var selectionActive: Bool = false
    private(set) var lastHitPointInScreenSpace: CGPoint?
    private(set) var lastHitPointInClipSpace: simd_float4?
    private(set) var lastClipSpaceRay: (origin: simd_float4, direction: simd_float4)?
    private(set) var lastUnrotatedWorldSpaceRay: (origin: simd_float4, direction: simd_float4)?
    private(set) var lastWorldSpaceRay: (origin: simd_float3, direction: simd_float3)?
    
    init() {}
    
    func hit(
        at point: CGPoint,
        viewSize: CGSize,
        camera: Camera,
        cameraPosition: simd_float3,
        rotationMatrix: simd_float4x4
    ) {
        withAnimation {
            selectionActive = true
        }
        
        // Screen space
        self.lastHitPointInScreenSpace = point
        
        // Clip space
        let clipX = (2 * Float(point.x)) / Float(viewSize.width) - 1
        let clipY = 1 - (2 * Float(point.y)) / Float(viewSize.height)
        let clipSpacePoint = simd_float4(clipX, clipY, 0, 1)
        self.lastHitPointInClipSpace = clipSpacePoint
        
        // View space
        let projectionMatrix = camera.projectionMatrix
        let inverseProjectionMatrix = projectionMatrix.inverse
        var eyeRay = inverseProjectionMatrix * clipSpacePoint
        eyeRay.z = -1
        eyeRay.w = 0
        let eyeRayOrigin = simd_float4(x: 0, y: 0, z: 0, w: 1)
        self.lastClipSpaceRay = (eyeRayOrigin, eyeRay)
        
        // Unrotated world space
        let modelViewMatrix = Transform.translationMatrix(cameraPosition)
        let viewModelMatrix = modelViewMatrix.inverse
        var unrotatedWorldRay = (viewModelMatrix * eyeRay)
        unrotatedWorldRay = normalize(unrotatedWorldRay)
        let unrotatedWorldRayOrigin = (viewModelMatrix * eyeRayOrigin)
        self.lastUnrotatedWorldSpaceRay = (unrotatedWorldRayOrigin, unrotatedWorldRay)
        
        // Rotated world space
        // TODO: Actual rotation matrix (model is slightly offset)
        let worldRayOrigin = rotationMatrix.inverse * unrotatedWorldRayOrigin
        let worldRayDirection = rotationMatrix.inverse * unrotatedWorldRay
        self.lastWorldSpaceRay = (worldRayOrigin.xyz, worldRayDirection.xyz)
    }
    
    func deselect() {
        withAnimation {
            selectionActive = false
        }
    }
}
