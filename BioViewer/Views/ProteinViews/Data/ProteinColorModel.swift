//
//  ColorScene.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 25/11/21.
//

import Foundation
import simd
import SwiftUI

enum ProteinColorByOption: PickableEnum {
    case element
    case subunit
    case residue
    
    var displayName: String {
        switch self {
        case .element:
            return NSLocalizedString("Element", comment: "")
        case .subunit:
            return NSLocalizedString("Subunit", comment: "")
        case .residue:
            return NSLocalizedString("Residue", comment: "")
        }
    }
    
    var shortcutKey: KeyEquivalent {
        switch self {
        case .element:
            return "1"
        case .subunit:
            return "2"
        case .residue:
            return "3"
        }
    }

}

extension ProteinViewModel {
    
    // MARK: - Initialization
    
    func initElementColors() {
        // Preselected element color palette
        elementColors = []
        for atomElementIndex in 0..<ATOM_TYPE_COUNT {
            if let element = AtomElement(rawValue: UInt8(atomElementIndex)) {
                elementColors.append(element.defaultColor)
            } else {
                elementColors.append(AtomElement.unknown.defaultColor)
            }
        }
    }
    
    func initResidueColors() {
        // Preselected element color palette
        residueColors = []
        for residue in Residue.allCases {
            residueColors.append(residue.defaultColor)
        }
    }
    
    func initSubunitColors() {
        subunitColors = []
        // Preselected color palette
        let fixedColorPalette =
            [
                Color(.displayP3, red: 0/255, green: 177/255, blue: 228/255, opacity: 1),
                Color(.displayP3, red: 199/255, green: 0/255, blue: 156/255, opacity: 1),
                Color(.displayP3, red: 194/255, green: 104/255, blue: 1/255, opacity: 1),
                Color(.displayP3, red: 27/255, green: 170/255, blue: 0/255, opacity: 1),
                Color(.displayP3, red: 0.917, green: 0.085, blue: 0.183, opacity: 1),
                Color(.displayP3, red: 0.225, green: 0.129, blue: 0.650, opacity: 1),
                Color(.displayP3, red: 0.894, green: 0.682, blue: 0.203, opacity: 1),
                Color(.displayP3, red: 0.216, green: 0.945, blue: 0.657, opacity: 1)
            ]
        for index in 0..<fixedColorPalette.count {
            guard index < MAX_SUBUNIT_COLORS else { return }
            subunitColors.append(fixedColorPalette[index])
        }
        // If there are more subunits than colors in the preselected color palette, chose them
        // at random.
        for _ in fixedColorPalette.count..<Int(MAX_SUBUNIT_COLORS) {
            subunitColors.append(randomColor())
        }
    }
    
    // MARK: - Updates
    
    func updatedFillColor() -> FillColorInput {
        
        var fillColor = FillColorInput()
        
        fillColor.colorByElement = 0.0
        fillColor.colorByResidue = 0.0
        fillColor.colorBySubunit = 0.0
        
        switch colorBy {
        case .element:
            fillColor.colorByElement = 1.0
        case .residue:
            fillColor.colorByResidue = 1.0
        case .subunit:
            fillColor.colorBySubunit = 1.0
        default:
            break
        }
        
        // WORKAROUND: C arrays with fixed sizes, such as the ones defined in FillColorInput, are
        // imported in Swift as tuples. To access its contents, we must use an unsafe pointer.
        withUnsafeMutableBytes(of: &fillColor.element_color) { rawPtr -> Void in
            for index in 0..<min(elementColors.count, Int(MAX_ELEMENT_COLORS)) {
                guard let ptrAddress = rawPtr.baseAddress else {
                    return
                }
                let ptr = (ptrAddress + MemoryLayout<simd_float4>.stride * index).assumingMemoryBound(to: simd_float4.self)
                // TO-DO:
                guard let simdColor = getSIMDColor(atomColor: elementColors[index].cgColor) else {
                    NSLog("Unable to get SIMD color from CGColor for atom element coloring.")
                    return
                }
                ptr.pointee = simdColor
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
                // TO-DO:
                guard let simdColor = getSIMDColor(atomColor: residueColors[index].cgColor) else {
                    NSLog("Unable to get SIMD color from CGColor for residue coloring.")
                    return
                }
                ptr.pointee = simdColor
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
                // TO-DO:
                guard let simdColor = getSIMDColor(atomColor: subunitColors[index].cgColor) else {
                    NSLog("Unable to get SIMD color from CGColor for protein subunit coloring.")
                    return
                }
                ptr.pointee = simdColor
            }
        }
        
        return fillColor
    }
    
    // MARK: - Utility functions
    
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
