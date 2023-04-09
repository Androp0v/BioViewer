//
//  ComputePipelines.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 21/2/22.
//

import Foundation
import Metal

extension ProteinRenderer {
    
    // MARK: - Fill color pass
    
    func makeSimpleFillColorComputePipelineState(device: MTLDevice) {
        // Setup pipeline
        guard let defaultLibrary = try? device.makeDefaultLibrary(bundle: Bundle(for: ProteinRenderer.self)) else {
            NSLog("Failed to retrieve the default library.")
            return
        }
        
        guard let simpleFillColorKernel = defaultLibrary.makeFunction(name: "fill_color_buffer_simple") else {
            NSLog("Failed to make fill color (simple) kernel.")
            return
        }

        simpleFillColorComputePipelineState = try? device.makeComputePipelineState(function: simpleFillColorKernel)
    }
    
    func makeFillColorComputePipelineState(device: MTLDevice) {
        // Setup pipeline
        guard let defaultLibrary = try? device.makeDefaultLibrary(bundle: Bundle(for: ProteinRenderer.self)) else {
            fatalError()
        }
        
        guard let fillColorKernel = defaultLibrary.makeFunction(name: "fill_color_buffer") else {
            NSLog("Failed to make fill color kernel")
            return
        }

        fillColorComputePipelineState = try? device.makeComputePipelineState(function: fillColorKernel)
    }
    
    // MARK: - Shadow blurring pass
    
    func makeShadowBlurringComputePipelineState(device: MTLDevice) {
        // Setup pipeline
        guard let defaultLibrary = try? device.makeDefaultLibrary(bundle: Bundle(for: ProteinRenderer.self)) else {
            NSLog("Failed to retrieve the default library.")
            return
        }
        
        guard let shadowBlurKernel = defaultLibrary.makeFunction(name: "shadow_blur") else {
            NSLog("Failed to make shadow blur kernel")
            return
        }

        shadowBlurPipelineState = try? device.makeComputePipelineState(function: shadowBlurKernel)
    }
}
