//
//  ProteinShadowsViewModel.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/1/23.
//

import Foundation
import SwiftUI

class SunDirection {
    var theta: Angle
    var phi: Angle
    
    init() {
        self.theta = Angle(degrees: 45)
        self.phi = Angle(degrees: 45)
    }
    
    init(theta: Angle, phi: Angle) {
        self.theta = theta
        self.phi = phi
    }
}

class ProteinShadowsViewModel: ObservableObject {
    
    weak var proteinViewModel: ProteinViewModel?
    
    @Published var sunDirection = SunDirection() {
        didSet {
            Task {
                await proteinViewModel?.renderer.mutableState.scene.setSunDirection(
                    theta: sunDirection.theta,
                    phi: sunDirection.phi
                )
                await proteinViewModel?.renderer.mutableState.scene.needsRedraw = true
            }
        }
    }
    
    @Published var hasShadows: Bool = true {
        didSet {
            Task {
                await proteinViewModel?.renderer.mutableState.scene.hasShadows = hasShadows
            }
        }
    }
    @Published var shadowStrength: Float = 0.4 {
        didSet {
            Task {
                await proteinViewModel?.renderer.mutableState.scene.shadowStrength = shadowStrength
            }
        }
    }
    /// Whether depth cueing should be used in the scene.
    @Published var hasDepthCueing: Bool = false {
        didSet {
            Task {
                await proteinViewModel?.renderer.mutableState.scene.hasDepthCueing = hasDepthCueing
            }
        }
    }
    @Published var depthCueingStrength: Float = 0.3 {
        didSet {
            Task {
                await proteinViewModel?.renderer.mutableState.scene.depthCueingStrength = depthCueingStrength
            }
        }
    }
}
