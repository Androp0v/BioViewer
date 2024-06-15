//
//  ProteinGraphicsSettings.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 27/4/23.
//

import Foundation

@MainActor @Observable class ProteinGraphicsSettings {
    
    weak var proteinViewModel: ProteinViewModel?
    
    var metalFXUpscalingMode: MetalFXUpscalingMode = .none {
        didSet {
            guard let renderer = proteinViewModel?.renderer else {
                return
            }
            switch metalFXUpscalingMode {
            case .temporal, .spatial:
                self.ssaaFactor = 1.5
                self.metalFXFactor = 1.5
            case .none:
                self.ssaaFactor = 1.0
                self.metalFXFactor = 1.0
            }
            Task {
                await renderer.mutableState.updateMetalFXUpscalingMode(
                    to: metalFXUpscalingMode,
                    renderer: renderer
                )
            }
        }
    }
        
    var ssaaFactor: Float = 1.0 {
        didSet {
            Task {
                await updateFactors()
            }
        }
    }
    var metalFXFactor: Float = 1.5 {
        didSet {
            Task {
                await updateFactors()
            }
        }
    }
    
    private func updateFactors() async {
        guard let renderer = proteinViewModel?.renderer else {
            return
        }
        await renderer.mutableState.updateProteinRenderFactors(
            ssaa: ssaaFactor,
            metalFXUpscaling: metalFXFactor
        )
    }
}
