//
//  FillAtomColorArray.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 22/1/22.
//

import Foundation
import Metal
import SwiftUI

extension MetalScheduler {

    // MARK: - Create new color buffer

    public func createAtomColorArray(protein: Protein, subunitBuffer: MTLBuffer, atomTypeBuffer: MTLBuffer, colorList: [Color]?, colorBy: Int?) -> MTLBuffer? {
        
        // Get the number of configurations
        let configurationCount = protein.configurationCount
        
        guard let colorList = colorList else { return nil }
        guard let colorBy = colorBy else { return nil }
        
        // WORKAROUND: The memory layout should conform to simd_half3's stride, which is
        // syntactic sugar for SIMD3<Float16>, but Float16 is (still) unavailable on macOS
        // due to lack of support on x86. We assume SIMD3<Int16> is packed in the same way
        // Metal packs the half3 type.
        guard let generatedColorBuffer = device.makeBuffer(
            length: protein.atomCount * configurationCount * MemoryLayout<SIMD3<Int16>>.stride
        ) else { return nil }
        
        updateAtomColorArray(colorBuffer: generatedColorBuffer,
                             protein: protein,
                             subunitBuffer: subunitBuffer,
                             atomTypeBuffer: atomTypeBuffer,
                             colorList: colorList,
                             colorBy: colorBy)
        
        return generatedColorBuffer
    }
    
    // MARK: - Update existing color buffer
    
    public func updateAtomColorArray(colorBuffer: MTLBuffer?, protein: Protein?, subunitBuffer: MTLBuffer?, atomTypeBuffer: MTLBuffer?, colorList: [Color], colorBy: Int) {
        metalDispatchQueue.sync {
            
            guard let colorBuffer = colorBuffer else { return }
            guard let protein = protein else { return }
            guard let subunitBuffer = subunitBuffer else { return }
            guard let atomTypeBuffer = atomTypeBuffer else { return }
            
            var colorInput = fillColorInputFromColorList(colorList: colorList, colorBy: colorBy)
            
            // Get the number of configurations
            let configurationCount = protein.configurationCount

            // Make Metal command buffer
            guard let buffer = queue?.makeCommandBuffer() else {
                return
            }

            // Set Metal compute encoder
            guard let computeEncoder = buffer.makeComputeCommandEncoder() else {
                return
            }

            // Check if the function needs to be compiled
            if fillColorArrayBundle.requiresBuilding(newFunctionParameters: nil) {
                fillColorArrayBundle.createPipelineState(functionName: "fill_color_buffer",
                                                            library: self.library,
                                                            device: self.device,
                                                            constantValues: nil)
            }
            guard let pipelineState = fillColorArrayBundle.getPipelineState(functionParameters: nil) else {
                return
            }

            // Set compute pipeline state for current arguments
            computeEncoder.setComputePipelineState(pipelineState)

            // Set buffer contents
            computeEncoder.setBuffer(colorBuffer,
                                     offset: 0,
                                     index: 0)
            computeEncoder.setBuffer(subunitBuffer,
                                     offset: 0,
                                     index: 1)
            computeEncoder.setBuffer(atomTypeBuffer,
                                     offset: 0,
                                     index: 2)
            
            computeEncoder.setBytes(&colorInput, length: MemoryLayout<FillColorInput>.stride, index: 3)
            
            // Schedule the threads
            if device.supportsFamily(.apple3) {
                // Create threads and threadgroup sizes
                let threadsPerArray = MTLSizeMake(protein.atomCount * configurationCount, 1, 1)
                let groupSize = MTLSizeMake(pipelineState.maxTotalThreadsPerThreadgroup, 1, 1)
                // Dispatch threads
                computeEncoder.dispatchThreads(threadsPerArray, threadsPerThreadgroup: groupSize)
            } else {
                // LEGACY: Older devices do not support non-uniform threadgroup sizes
                let groupSize = MTLSizeMake(pipelineState.maxTotalThreadsPerThreadgroup, 1, 1)
                let threadGroupsPerGrid = MTLSizeMake(Int(ceilf(Float(protein.atomCount * configurationCount)
                                                                / Float(pipelineState.maxTotalThreadsPerThreadgroup))), 1, 1)
                // Dispatch threadgroups
                computeEncoder.dispatchThreadgroups(threadGroupsPerGrid, threadsPerThreadgroup: groupSize)
            }

            // REQUIRED: End the compute encoder encoding
            computeEncoder.endEncoding()

            // Commit the buffer contents
            buffer.commit()

            // Wait until the computation is finished!
            buffer.waitUntilCompleted()
        }
    }
    
    // MARK: - Utility functions
    
    private func fillColorInputFromColorList(colorList: [Color], colorBy: Int) -> FillColorInput {
        
        var fillColor = FillColorInput()
        fillColor.colorBySubunit = Int8(colorBy)
        
        // WORKAROUND: C arrays with fixed sizes, such as the ones defined in FillColorInput, are
        // imported in Swift as tuples. To access its contents, we must use an unsafe pointer.
        withUnsafeMutableBytes(of: &fillColor.atom_color) { rawPtr -> Void in
            for index in 0..<min(colorList.count, Int(MAX_ATOM_COLORS)) {
                guard let ptrAddress = rawPtr.baseAddress else {
                    return
                }
                let ptr = (ptrAddress + MemoryLayout<simd_float4>.stride * index).assumingMemoryBound(to: simd_float4.self)
                // TO-DO:
                guard let simdColor = getSIMDColor(atomColor: colorList[index].cgColor) else {
                    NSLog("Unable to get SIMD color from CGColor for protein subunit coloring.")
                    return
                }
                ptr.pointee = simdColor
            }
        }
        
        return fillColor
    }
    
    private func getSIMDColor(atomColor: CGColor?) -> simd_float4? {
        
        guard let atomColor = atomColor else {
            return nil
        }

        // Convert color to RGB from other color spaces (i.e. grayscale) as MTLClearColor requires
        // a RGBA value.
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let rgbaColor = atomColor.converted(to: rgbColorSpace, intent: .defaultIntent, options: nil) else {
            return nil
        }
        
        // We expect 4 color components in RGBA
        guard rgbaColor.numberOfComponents == 4 else {
            return nil
        }
        guard let rgbaColorComponents = rgbaColor.components else {
            return nil
        }
        
        return simd_float4(Float(rgbaColorComponents[0]),
                           Float(rgbaColorComponents[1]),
                           Float(rgbaColorComponents[2]),
                           Float(rgbaColorComponents[3]))
    }
}
