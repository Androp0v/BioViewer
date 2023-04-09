//
//  MetalFXUpscaling.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 9/4/23.
//

import Foundation
import MetalKit

extension ProteinRenderer.MutableState {
        
    func metalFXUpscaling(
        renderer: ProteinRenderer,
        commandBuffer: MTLCommandBuffer,
        sourceTexture: MTLTexture,
        outputTexture: MTLTexture
    ) {
        if let spatialScaler = renderer.metalFXSpatialScaler {
            spatialScaler.colorTexture = sourceTexture
            spatialScaler.outputTexture = outputTexture
            spatialScaler.encode(commandBuffer: commandBuffer)
        }
    }
}
