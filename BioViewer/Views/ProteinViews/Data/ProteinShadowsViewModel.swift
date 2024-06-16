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

@MainActor @Observable class ProteinShadowsViewModel {
    
    weak var proteinViewModel: ProteinViewModel?
    
    var sunDirection = SunDirection() {
        didSet {
            Task {
                await proteinViewModel?.renderer.setSunDirection(
                    theta: sunDirection.theta,
                    phi: sunDirection.phi
                )
            }
        }
    }
    
    var hasShadows: Bool = true {
        didSet {
            Task {
                await proteinViewModel?.renderer.setHasShadows(hasShadows)
            }
        }
    }
    var shadowStrength: Float = 0.7 {
        didSet {
            Task {
                await proteinViewModel?.renderer.setShadowStrength(shadowStrength)
            }
        }
    }
    /// Whether depth cueing should be used in the scene.
    var hasDepthCueing: Bool = false {
        didSet {
            Task {
                await proteinViewModel?.renderer.setHasDepthCueing(hasDepthCueing)
            }
        }
    }
    var depthCueingStrength: Float = 0.6 {
        didSet {
            Task {
                await proteinViewModel?.renderer.setDepthCueingStrength(depthCueingStrength)
            }
        }
    }
    var hasAmbientOcclusion: Bool = false {
        didSet {
            if hasAmbientOcclusion {
                Task {
                    guard let proteinViewModel else { return }
                    await proteinViewModel.renderer.computeAmbientOcclusion(
                        atomPositions: proteinViewModel.dataSource.getFirstProtein()!.atoms,
                        atomRadii: [Float.zero]
                    )
                }
            }
        }
    }
}
