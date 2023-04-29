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
                await proteinViewModel?.renderer.mutableState.setSunDirection(
                    theta: sunDirection.theta,
                    phi: sunDirection.phi
                )
            }
        }
    }
    
    @Published var hasShadows: Bool = true {
        didSet {
            Task {
                await proteinViewModel?.renderer.mutableState.setHasShadows(hasShadows)
            }
        }
    }
    @Published var shadowStrength: Float = 0.4 {
        didSet {
            Task {
                await proteinViewModel?.renderer.mutableState.setShadowStrength(shadowStrength)
            }
        }
    }
    /// Whether depth cueing should be used in the scene.
    @Published var hasDepthCueing: Bool = false {
        didSet {
            Task {
                await proteinViewModel?.renderer.mutableState.setHasDepthCueing(hasDepthCueing)
            }
        }
    }
    @Published var depthCueingStrength: Float = 0.3 {
        didSet {
            Task {
                await proteinViewModel?.renderer.mutableState.setDepthCueingStrength(depthCueingStrength)
            }
        }
    }
}
