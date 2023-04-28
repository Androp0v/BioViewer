//
//  ProteinGraphicsSettings.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 27/4/23.
//

import Foundation

class ProteinGraphicsSettings: ObservableObject {
    
    weak var proteinViewModel: ProteinViewModel?
    
    @Published var metalFXUpscalingMode: MetalFXUpscalingMode = .none {
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
                await renderer.protectedMutableState.updateMetalFXUpscalingMode(
                    to: metalFXUpscalingMode,
                    renderer: renderer
                )
            }
        }
    }
        
    @Published var ssaaFactor: Float = 1.0 {
        didSet {
            Task {
                await updateFactors()
            }
        }
    }
    @Published var metalFXFactor: Float = 1.5 {
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
        await renderer.protectedMutableState.updateProteinRenderFactors(
            ssaa: ssaaFactor,
            metalFXUpscaling: metalFXFactor,
            renderer: renderer
        )
    }
}
