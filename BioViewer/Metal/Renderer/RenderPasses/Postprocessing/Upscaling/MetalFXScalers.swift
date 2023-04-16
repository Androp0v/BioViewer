//
//  MetalFXScalers.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 9/4/23.
//

import Foundation
import MetalFX
import MetalKit

extension ProteinRenderer {
    
    /// Creates the MetalFX spatial scaler.
    func makeSpatialScaler(inputSize: MTLSize, outputSize: MTLSize) {
        let descriptor = MTLFXSpatialScalerDescriptor()
        descriptor.inputWidth = inputSize.width
        descriptor.inputHeight = inputSize.height
        descriptor.outputWidth = outputSize.width
        descriptor.outputHeight = outputSize.height
        descriptor.colorTextureFormat = .bgra8Unorm
        descriptor.outputTextureFormat = .bgra8Unorm
        descriptor.colorProcessingMode = .linear
        
        guard let spatialScaler = descriptor.makeSpatialScaler(device: device) else {
            print("The spatial scaler effect is not usable!")
            return
        }
        metalFXSpatialScaler = spatialScaler
    }
    
    /// Creates the MetalFX spatial scaler.
    func makeTemporalScaler(inputSize: MTLSize, outputSize: MTLSize) {
        let descriptor = MTLFXTemporalScalerDescriptor()
        descriptor.inputWidth = inputSize.width
        descriptor.inputHeight = inputSize.height
        descriptor.outputWidth = outputSize.width
        descriptor.outputHeight = outputSize.height
        descriptor.colorTextureFormat = .bgra8Unorm
        descriptor.depthTextureFormat = .r32Float
        descriptor.motionTextureFormat = ProteinRenderedTextures.motionPixelFormat
        descriptor.outputTextureFormat = .bgra8Unorm
        
        guard let temporalScaler = descriptor.makeTemporalScaler(device: device) else {
            print("The temporal scaler effect is not usable!")
            return
        }
        metalFXTemporalScaler = temporalScaler
    }
}
