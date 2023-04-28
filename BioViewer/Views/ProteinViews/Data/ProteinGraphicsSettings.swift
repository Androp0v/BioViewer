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
    
}
