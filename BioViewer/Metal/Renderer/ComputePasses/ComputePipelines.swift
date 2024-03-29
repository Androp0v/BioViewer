//
//  ComputePipelines.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 21/2/22.
//

import Foundation
import Metal

extension MutableState {
    
    // MARK: - Fill color pass
    
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
    
    // MARK: - Motion texture pass
    
    func makeMotionComputePipelineState(device: MTLDevice) {
        // Setup pipeline
        guard let defaultLibrary = try? device.makeDefaultLibrary(bundle: Bundle(for: ProteinRenderer.self)) else {
            NSLog("Failed to retrieve the default library.")
            return
        }
        
        guard let motionKernel = defaultLibrary.makeFunction(name: "motion_texture") else {
            NSLog("Failed to make shadow blur kernel")
            return
        }
        
        let descriptor = MTLComputePipelineDescriptor()
        descriptor.computeFunction = motionKernel
        descriptor.label = "Motion Texture Pass"
        motionPipelineState = try? device.makeComputePipelineState(
            descriptor: descriptor,
            options: MTLPipelineOption()
        ).0
    }
}
