//
//  ProteinShadowsViewModel.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/1/23.
//

import Foundation
import SwiftUI

class ProteinShadowsViewModel: ObservableObject {
    
    weak var proteinViewModel: ProteinViewModel?
    
    class SunDirection {
        var theta: Angle = Angle(degrees: 90)
        var phi: Angle = Angle(degrees: 45)
    }
    
    @Published var sunDirection = SunDirection() {
        didSet {
            proteinViewModel?.renderer.scene.setSunDirection(
                theta: sunDirection.theta,
                phi: sunDirection.phi
            )
            proteinViewModel?.renderer.scene.needsRedraw = true
        }
    }
    
    @Published var hasShadows: Bool = true {
        didSet {
            proteinViewModel?.renderer.scene.hasShadows = hasShadows
        }
    }
    @Published var shadowStrength: Float = 0.4 {
        didSet {
            proteinViewModel?.renderer.scene.shadowStrength = shadowStrength
        }
    }
    /// Whether depth cueing should be used in the scene.
    @Published var hasDepthCueing: Bool = false {
        didSet {
            proteinViewModel?.renderer.scene.hasDepthCueing = hasDepthCueing
        }
    }
    @Published var depthCueingStrength: Float = 0.3 {
        didSet {
            proteinViewModel?.renderer.scene.depthCueingStrength = depthCueingStrength
        }
    }
}
