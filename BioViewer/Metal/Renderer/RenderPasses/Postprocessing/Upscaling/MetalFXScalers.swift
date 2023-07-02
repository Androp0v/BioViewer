//
//  MetalFXScalers.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 9/4/23.
//

import Foundation
#if canImport(MetalFX)
import MetalFX
#endif
import MetalKit

extension MutableState {
    
    /// Creates the MetalFX spatial scaler.
    func makeSpatialScaler(inputSize: MTLSize, outputSize: MTLSize) {
        #if canImport(MetalFX)
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
        #else
        print("Can't import MetalFX!")
        #endif
    }
    
    /// Creates the MetalFX spatial scaler.
    func makeTemporalScaler(inputSize: MTLSize, outputSize: MTLSize) {
        #if canImport(MetalFX)
        let descriptor = MTLFXTemporalScalerDescriptor()
        descriptor.inputWidth = inputSize.width
        descriptor.inputHeight = inputSize.height
        descriptor.outputWidth = outputSize.width
        descriptor.outputHeight = outputSize.height
        descriptor.colorTextureFormat = .bgra8Unorm
        descriptor.depthTextureFormat = .depth32Float
        descriptor.motionTextureFormat = ProteinRenderedTextures.motionPixelFormat
        descriptor.outputTextureFormat = .bgra8Unorm
        descriptor.isAutoExposureEnabled = false
        
        guard let temporalScaler = descriptor.makeTemporalScaler(device: device) else {
            print("The temporal scaler effect is not usable!")
            return
        }
        temporalScaler.motionVectorScaleX = Float(inputSize.width)
        temporalScaler.motionVectorScaleY = Float(inputSize.height)
        metalFXTemporalScaler = temporalScaler
        #else
        print("Can't import MetalFX!")
        #endif
    }
}
