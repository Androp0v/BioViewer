//
//  ColorScene.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 25/11/21.
//

import Foundation

public enum ProteinColorByOption {
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
            // swift as tuples. To access its contents, we must use an unsafe pointer.
            let max_atom_colors = Mirror(reflecting: self.frameData.atomColor).children.count
            withUnsafeMutableBytes(of: &self.frameData.atomColor) { rawPtr -> Void in
                for index in 0..<max_atom_colors {
                    guard let ptrAddress = rawPtr.baseAddress else {
                        return
                    }
                    let ptr = (ptrAddress + MemoryLayout<simd_float4>.stride * index).assumingMemoryBound(to: simd_float4.self)
                    // TO-DO:
                    guard let simdColor = getSIMDColor(atomColor: CGColor.init(red: 1, green: 1, blue: 1, alpha: 1)) else {
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
    
    // MARK: - Utility functions
    
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
