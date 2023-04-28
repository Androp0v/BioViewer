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
            Task {
                if let renderer = proteinViewModel?.renderer {
                    await renderer.protectedMutableState.updateMetalFXUpscalingMode(
                        to: metalFXUpscalingMode,
                        renderer: renderer
                    )
                }
            }
        }
    }
    @Published var ssaaFactor: Float = 1.0
    @Published var metalFXFactor: Float = 1.5
}
