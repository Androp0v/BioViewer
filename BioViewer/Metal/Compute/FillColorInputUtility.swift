//
//  FillColorInputUtility.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 25/2/22.
//

import Foundation
import simd
import SwiftUI

class FillColorInputUtility {
    
    static func interpolateFillColorInput(start: FillColorInput, end: FillColorInput, fraction: Float) -> FillColorInput {
        
        var fillColor = FillColorInput()
        var startFill = start
        var endFill = end
        
        fillColor.colorByElement = start.colorByElement * (1 - fraction) + end.colorByElement * fraction
        fillColor.colorByResidue = start.colorByResidue * (1 - fraction) + end.colorByResidue * fraction
        fillColor.colorBySubunit = start.colorBySubunit * (1 - fraction) + end.colorBySubunit * fraction
        
        var elementColors = [simd_float4](repeating: .zero, count: Int(MAX_ELEMENT_COLORS))
        var residueColors = [simd_float4](repeating: .zero, count: Int(MAX_RESIDUE_COLORS))
        var subunitColors = [simd_float4](repeating: .zero, count: Int(MAX_SUBUNIT_COLORS))
        
        // MARK: - Element colors
        
        // WORKAROUND: C arrays with fixed sizes, such as the ones defined in FillColorInput, are
        // imported in Swift as tuples. To access its contents, we must use an unsafe pointer.
        withUnsafeMutableBytes(of: &startFill.element_color) { rawPtr -> Void in
            for index in 0..<Int(MAX_ELEMENT_COLORS) {
                guard let ptrAddress = rawPtr.baseAddress else {
                    return
                }
                let ptr = (ptrAddress + MemoryLayout<simd_float4>.stride * index).assumingMemoryBound(to: simd_float4.self)
                elementColors[index] += ptr.pointee * (1 - fraction)
            }
        }
        // WORKAROUND: C arrays with fixed sizes, such as the ones defined in FillColorInput, are
        // imported in Swift as tuples. To access its contents, we must use an unsafe pointer.
        withUnsafeMutableBytes(of: &endFill.element_color) { rawPtr -> Void in
            for index in 0..<Int(MAX_ELEMENT_COLORS) {
                guard let ptrAddress = rawPtr.baseAddress else {
                    return
                }
                let ptr = (ptrAddress + MemoryLayout<simd_float4>.stride * index).assumingMemoryBound(to: simd_float4.self)
                elementColors[index] += ptr.pointee * fraction
            }
        }
        
        // MARK: - Residue colors
        
        // WORKAROUND: C arrays with fixed sizes, such as the ones defined in FillColorInput, are
        // imported in Swift as tuples. To access its contents, we must use an unsafe pointer.
        withUnsafeMutableBytes(of: &startFill.residue_color) { rawPtr -> Void in
            for index in 0..<Int(MAX_RESIDUE_COLORS) {
                guard let ptrAddress = rawPtr.baseAddress else {
                    return
                }
                let ptr = (ptrAddress + MemoryLayout<simd_float4>.stride * index).assumingMemoryBound(to: simd_float4.self)
                residueColors[index] += ptr.pointee * (1 - fraction)
            }
        }
        // WORKAROUND: C arrays with fixed sizes, such as the ones defined in FillColorInput, are
        // imported in Swift as tuples. To access its contents, we must use an unsafe pointer.
        withUnsafeMutableBytes(of: &endFill.residue_color) { rawPtr -> Void in
            for index in 0..<Int(MAX_RESIDUE_COLORS) {
                guard let ptrAddress = rawPtr.baseAddress else {
                    return
                }
                let ptr = (ptrAddress + MemoryLayout<simd_float4>.stride * index).assumingMemoryBound(to: simd_float4.self)
                residueColors[index] += ptr.pointee * fraction
            }
        }
        
        // MARK: - Subunit colors
        
        // WORKAROUND: C arrays with fixed sizes, such as the ones defined in FillColorInput, are
        // imported in Swift as tuples. To access its contents, we must use an unsafe pointer.
        withUnsafeMutableBytes(of: &startFill.subunit_color) { rawPtr -> Void in
            for index in 0..<Int(MAX_SUBUNIT_COLORS) {
                guard let ptrAddress = rawPtr.baseAddress else {
                    return
                }
                let ptr = (ptrAddress + MemoryLayout<simd_float4>.stride * index).assumingMemoryBound(to: simd_float4.self)
                subunitColors[index] += ptr.pointee * (1 - fraction)
            }
        }
        // WORKAROUND: C arrays with fixed sizes, such as the ones defined in FillColorInput, are
        // imported in Swift as tuples. To access its contents, we must use an unsafe pointer.
        withUnsafeMutableBytes(of: &endFill.subunit_color) { rawPtr -> Void in
            for index in 0..<Int(MAX_SUBUNIT_COLORS) {
                guard let ptrAddress = rawPtr.baseAddress else {
                    return
                }
                let ptr = (ptrAddress + MemoryLayout<simd_float4>.stride * index).assumingMemoryBound(to: simd_float4.self)
                subunitColors[index] += ptr.pointee * fraction
            }
        }
                
        // MARK: - Write back
        
        // WORKAROUND: C arrays with fixed sizes, such as the ones defined in FillColorInput, are
        // imported in Swift as tuples. To access its contents, we must use an unsafe pointer.
        withUnsafeMutableBytes(of: &fillColor.element_color) { rawPtr -> Void in
            for index in 0..<min(elementColors.count, Int(MAX_ELEMENT_COLORS)) {
                guard let ptrAddress = rawPtr.baseAddress else {
                    return
                }
                let ptr = (ptrAddress + MemoryLayout<simd_float4>.stride * index).assumingMemoryBound(to: simd_float4.self)
                ptr.pointee = elementColors[index]
            }
        }
        
        // WORKAROUND: C arrays with fixed sizes, such as the ones defined in FillColorInput, are
        // imported in Swift as tuples. To access its contents, we must use an unsafe pointer.
        withUnsafeMutableBytes(of: &fillColor.residue_color) { rawPtr -> Void in
            for index in 0..<min(residueColors.count, Int(MAX_RESIDUE_COLORS)) {
                guard let ptrAddress = rawPtr.baseAddress else {
                    return
                }
                let ptr = (ptrAddress + MemoryLayout<simd_float4>.stride * index).assumingMemoryBound(to: simd_float4.self)
                ptr.pointee = residueColors[index]
            }
        }
        
        // WORKAROUND: C arrays with fixed sizes, such as the ones defined in FillColorInput, are
        // imported in Swift as tuples. To access its contents, we must use an unsafe pointer.
        withUnsafeMutableBytes(of: &fillColor.subunit_color) { rawPtr -> Void in
            for index in 0..<min(subunitColors.count, Int(MAX_SUBUNIT_COLORS)) {
                guard let ptrAddress = rawPtr.baseAddress else {
                    return
                }
                let ptr = (ptrAddress + MemoryLayout<simd_float4>.stride * index).assumingMemoryBound(to: simd_float4.self)
                ptr.pointee = subunitColors[index]
            }
        }
        
        return fillColor
    }
}
