//
//  SelectionModel.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/2/24.
//

import BioViewerFoundation
import Foundation
import simd
import SwiftUI

enum SelectionOption: PickableEnum {
    #if DEBUG
    case debug
    #endif
    case element
    case chain
    case residue
    
    var displayName: String {
        switch self {
        #if DEBUG
        case .debug:
            return "Debug"
        #endif
        case .element:
            return "Element"
        case .chain:
            return "Chain"
        case .residue:
            return "Residue"
        }
    }
}

@MainActor @Observable class SelectionModel {
    
    private(set) var selectionActive: Bool = false
    var selectionOption: SelectionOption = .element
    private(set) var didHit: Bool = false
    private(set) var coordinatesHit: simd_float3?
    private(set) var elementHit: AtomElement?
    private(set) var chainHit: ChainID?
    private(set) var residueHit: Residue?
    
    // DEBUG:
    
    private(set) var lastHitPointInScreenSpace: CGPoint?
    private(set) var lastHitPointInClipSpace: simd_float4?
    private(set) var lastClipSpaceRay: Ray?
    private(set) var lastUnrotatedWorldSpaceRay: Ray?
    private(set) var lastWorldSpaceRay: Ray?
    
    init() {}
    
    func hit(
        at point: CGPoint,
        viewSize: CGSize,
        camera: Camera,
        cameraPosition: simd_float3,
        rotationQuaternion: simd_quatf,
        modelTranslationMatrix: simd_float4x4,
        atomRadii: AtomRadii,
        dataSource: ProteinDataSource?
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
        eyeRay.z = 1
        eyeRay.w = 0
        let eyeRayOrigin = simd_float4(x: 0, y: 0, z: 0, w: 1)
        self.lastClipSpaceRay = Ray(
            origin: eyeRayOrigin.xyz,
            direction: eyeRay.xyz
        )
        
        // Unrotated world space
        let modelViewMatrix = Transform.translationMatrix(cameraPosition)
        let viewModelMatrix = modelViewMatrix.inverse
        var unrotatedWorldRay = (viewModelMatrix * eyeRay)
        unrotatedWorldRay = normalize(unrotatedWorldRay)
        let unrotatedWorldRayOrigin = (viewModelMatrix * eyeRayOrigin)
        self.lastUnrotatedWorldSpaceRay = Ray(
            origin: unrotatedWorldRayOrigin.xyz,
            direction: unrotatedWorldRay.xyz
        )
        
        // Translated and rotated world space
        let rotationMatrix = Transform.rotationMatrix(quaternion: rotationQuaternion)
        var worldRayOrigin = rotationMatrix.inverse * unrotatedWorldRayOrigin
        var worldRayDirection = rotationMatrix.inverse * unrotatedWorldRay
        worldRayOrigin = modelTranslationMatrix.inverse * worldRayOrigin
        worldRayDirection = modelTranslationMatrix.inverse * worldRayDirection
        let worldRay = Ray(
            origin: worldRayOrigin.xyz,
            direction: worldRayDirection.xyz
        )
        self.lastWorldSpaceRay = worldRay
        
        guard let dataSource else {
            self.didHit = false
            return
        }
        if let hitAtomIndex = hitTest(
            worldSpaceRay: worldRay, 
            atomRadii: atomRadii,
            dataSource: dataSource
        ) {
            withAnimation {
                self.didHit = true
                self.elementHit = dataSource.getFirstProtein()?.atomElements[hitAtomIndex]
                self.chainHit = dataSource.getFirstProtein()?.atomChainIDs?[hitAtomIndex]
                self.residueHit = dataSource.getFirstProtein()?.atomResidues?[hitAtomIndex]
                self.coordinatesHit = dataSource.getFirstProtein()?.atoms[hitAtomIndex]
            }
        } else {
            self.didHit = false
            deselect()
        }
    }
    
    func deselect() {
        withAnimation {
            selectionActive = false
        }
    }
    
    // MARK: - Intersection test
    
    func hitTest(worldSpaceRay: Ray, atomRadii: AtomRadii, dataSource: ProteinDataSource) -> Int? {
        guard let protein = dataSource.getFirstProtein() else {
            return nil
        }
        
        var minDistance: Float = .infinity
        var atomIndex: Int?
        for (index, atom) in protein.atoms.enumerated() {
            guard let intersection = intersect(
                worldSpaceRay,
                atomCenter: atom,
                radius: atomRadii.getRadiusOf(atomElement: protein.atomElements[index])
            ) else {
                continue
            }
            let intersectionDistance = distance(worldSpaceRay.origin, intersection.xyz)
            if intersectionDistance < minDistance {
                minDistance = intersectionDistance
                atomIndex = index
            }
        }
        if minDistance != .infinity, let atomIndex {
            return atomIndex
        }
        return nil
    }
    
    func intersect(_ ray: Ray, atomCenter position: simd_float3, radius: Float) -> simd_float4? {
        var t0, t1: Float
        let radius2 = radius * radius
        if (radius2 == 0) { return nil }
        let L = position - ray.origin
        let tca = simd_dot(L, ray.direction)
        
        let d2 = simd_dot(L, L) - tca * tca
        if (d2 > radius2) { return nil }
        let thc = sqrt(radius2 - d2)
        t0 = tca - thc
        t1 = tca + thc
        
        if (t0 > t1) {
            swap(&t0, &t1)
        }
        
        if t0 < 0 {
            t0 = t1
            if t0 < 0 {
                return nil
            }
        }
        
        return simd_float4(ray.origin + ray.direction * t0, 1)
    }
}
