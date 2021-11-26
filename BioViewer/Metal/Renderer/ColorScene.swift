//
//  ColorScene.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 25/11/21.
//

import Foundation
import simd
import SwiftUI

public enum ProteinColorByOption {
    static let none: Int = -1
    static let element: Int = 0
    static let subunit: Int = 1
}

extension MetalScene {
    
    func updateColors() {
        switch colorBy {
        case ProteinColorByOption.element:
            self.frameData.atomColor.0 = getSIMDColor(atomColor: cAtomColor.cgColor) ?? simd_float4.one
            self.frameData.atomColor.1 = getSIMDColor(atomColor: nAtomColor.cgColor) ?? simd_float4.one
            self.frameData.atomColor.2 = getSIMDColor(atomColor: hAtomColor.cgColor) ?? simd_float4.one
            self.frameData.atomColor.3 = getSIMDColor(atomColor: oAtomColor.cgColor) ?? simd_float4.one
            self.frameData.atomColor.4 = getSIMDColor(atomColor: sAtomColor.cgColor) ?? simd_float4.one
            self.frameData.atomColor.5 = getSIMDColor(atomColor: unknownAtomColor.cgColor) ?? simd_float4.one
        case ProteinColorByOption.subunit:
            // WORKAROUND: C arrays with fixed sizes, such as the ones defined in FrameData, are imported in
            // Swift as tuples. To access its contents, we must use an unsafe pointer.
            let max_atom_colors = Mirror(reflecting: self.frameData.atomColor).children.count
            // Avoid index out of range errors later
            guard subunitColors.count >= max_atom_colors else {
                NSLog("Subunit color array is smaller than MAX_ATOM_COLORS, unable to color by subunit.")
                return
            }
            withUnsafeMutableBytes(of: &self.frameData.atomColor) { rawPtr -> Void in
                for index in 0..<max_atom_colors {
                    guard let ptrAddress = rawPtr.baseAddress else {
                        return
                    }
                    let ptr = (ptrAddress + MemoryLayout<simd_float4>.stride * index).assumingMemoryBound(to: simd_float4.self)
                    // TO-DO:
                    guard let simdColor = getSIMDColor(atomColor: subunitColors[index].cgColor) else {
                        NSLog("Unable to get SIMD color from CGColor for protein subunit coloring.")
                        return
                    }
                    ptr.pointee = simdColor
                }
            }
        default:
            break
        }
    }
    
    func initSubunitColors() {
        let max_atom_colors = Mirror(reflecting: self.frameData.atomColor).children.count
        subunitColors = []
        // Preselected color palette
        let fixedColorPalette =
            [
                Color(.displayP3, red: 0/255, green: 177/255, blue: 228/255, opacity: 1),
                Color(.displayP3, red: 199/255, green: 0/255, blue: 156/255, opacity: 1),
                Color(.displayP3, red: 194/255, green: 104/255, blue: 1/255, opacity: 1),
                Color(.displayP3, red: 27/255, green: 170/255, blue: 0/255, opacity: 1)
            ]
        for index in 0..<fixedColorPalette.count {
            guard index < max_atom_colors else { return }
            subunitColors.append(fixedColorPalette[index])
        }
        // If there are more subunits than colors in the preselected color palette, chose them
        // at random.
        for index in fixedColorPalette.count..<max_atom_colors {
            subunitColors.append(randomColor())
        }
    }
    
    // MARK: - Utility functions
    
    private func randomSIMDColor() -> simd_float4? {
        let red = CGFloat.random(in: 0..<1)
        let green = CGFloat.random(in: 0..<1)
        let blue = CGFloat.random(in: 0..<1)
        let cgColor = CGColor(red: red, green: green, blue: blue, alpha: 1.0)
        return getSIMDColor(atomColor: cgColor)
    }
    
    private func randomColor() -> Color {
        let red = CGFloat.random(in: 0..<1)
        let green = CGFloat.random(in: 0..<1)
        let blue = CGFloat.random(in: 0..<1)
        return Color(cgColor: CGColor(red: red, green: green, blue: blue, alpha: 1.0))
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
