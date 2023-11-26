//
//  AtomRadii+Extensions.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/1/22.
//

import BioViewerFoundation
import Foundation
import CoreAudio

extension AtomRadii {
    
    static let defaultFixedRadius: Float = 0.4
    
    /// All atom radii set to zero.
    static let zero: AtomRadii = {
        var atomRadii = AtomRadii()

        // WORKAROUND: C arrays with fixed sizes, such as the ones defined in FillColorInput, are
        // imported in Swift as tuples. To access its contents, we must use an unsafe pointer.
        withUnsafeMutableBytes(of: &atomRadii.atomRadius) { rawPtr -> Void in
            for index in 0..<Int(ATOM_TYPE_COUNT) {
                guard let ptrAddress = rawPtr.baseAddress else {
                    return
                }
                let ptr = (ptrAddress + MemoryLayout<Float>.stride * index).assumingMemoryBound(to: Float.self)
                ptr.pointee = .zero
            }
        }
        
        return atomRadii
    }()
    
    /// Atom radii set to its actual Van der Waals radii.
    static let vanDerWaals: AtomRadii = {
        var atomRadii = AtomRadii()
        // WORKAROUND: C arrays with fixed sizes, such as the ones defined in FillColorInput, are
        // imported in Swift as tuples. To access its contents, we must use an unsafe pointer.
        withUnsafeMutableBytes(of: &atomRadii.atomRadius) { rawPtr -> Void in
            for index in 0..<Int(ATOM_TYPE_COUNT) {
                guard let ptrAddress = rawPtr.baseAddress else {
                    return
                }
                let ptr = (ptrAddress + MemoryLayout<Float>.stride * index).assumingMemoryBound(to: Float.self)
                let element = AtomElement(index: index)
                ptr.pointee = element.vanDerWaalsRadius
            }
        }
        return atomRadii
    }()
    
    /// Atom radii set to the default fixed radius.
    static let defaultFixed: AtomRadii = {
        var atomRadii = AtomRadii()
        // WORKAROUND: C arrays with fixed sizes, such as the ones defined in FillColorInput, are
        // imported in Swift as tuples. To access its contents, we must use an unsafe pointer.
        withUnsafeMutableBytes(of: &atomRadii.atomRadius) { rawPtr -> Void in
            for index in 0..<Int(ATOM_TYPE_COUNT) {
                guard let ptrAddress = rawPtr.baseAddress else {
                    return
                }
                let ptr = (ptrAddress + MemoryLayout<Float>.stride * index).assumingMemoryBound(to: Float.self)
                ptr.pointee = Self.defaultFixedRadius
            }
        }
        return atomRadii
    }()
    
    // MARK: - Functions
    
    static func scaledVanDerWaals(scale: Float) -> AtomRadii {
        // Cache the result for the common case
        if scale == 1.0 {
            return .vanDerWaals
        }
        // Otherwise, actually compute the value
        var atomRadii = AtomRadii()
        // WORKAROUND: C arrays with fixed sizes, such as the ones defined in FillColorInput, are
        // imported in Swift as tuples. To access its contents, we must use an unsafe pointer.
        withUnsafeMutableBytes(of: &atomRadii.atomRadius) { rawPtr -> Void in
            for index in 0..<Int(ATOM_TYPE_COUNT) {
                guard let ptrAddress = rawPtr.baseAddress else {
                    return
                }
                let ptr = (ptrAddress + MemoryLayout<Float>.stride * index).assumingMemoryBound(to: Float.self)
                let element = AtomElement(index: index)
                ptr.pointee = element.vanDerWaalsRadius * scale
            }
        }
        return atomRadii
    }
    
    static func fixed(radius: Float = 0.4) -> AtomRadii {
        
        if radius == Self.defaultFixedRadius {
            return .defaultFixed
        }
        
        var atomRadii = AtomRadii()
        // WORKAROUND: C arrays with fixed sizes, such as the ones defined in FillColorInput, are
        // imported in Swift as tuples. To access its contents, we must use an unsafe pointer.
        withUnsafeMutableBytes(of: &atomRadii.atomRadius) { rawPtr -> Void in
            for index in 0..<Int(ATOM_TYPE_COUNT) {
                guard let ptrAddress = rawPtr.baseAddress else {
                    return
                }
                let ptr = (ptrAddress + MemoryLayout<Float>.stride * index).assumingMemoryBound(to: Float.self)
                ptr.pointee = radius
            }
        }
        return atomRadii
    }
    
    static func interpolated(initial: AtomRadii, final: AtomRadii, progress: Float) -> AtomRadii {
        var atomRadii = AtomRadii()
        var initial = initial
        var final = final
        // WORKAROUND: C arrays with fixed sizes, such as the ones defined in FillColorInput, are
        // imported in Swift as tuples. To access its contents, we must use an unsafe pointer.
        withUnsafeMutableBytes(of: &atomRadii.atomRadius) { rawPtrOutput -> Void in
            withUnsafeMutableBytes(of: &initial.atomRadius) { rawPtrInitial -> Void in
                withUnsafeMutableBytes(of: &final.atomRadius) { rawPtrFinal -> Void in
                    for index in 0..<Int(ATOM_TYPE_COUNT) {
                        guard let ptrAddressOutput = rawPtrOutput.baseAddress else {
                            return
                        }
                        guard let ptrAddressInitial = rawPtrInitial.baseAddress else {
                            return
                        }
                        guard let ptrAddressFinal = rawPtrFinal.baseAddress else {
                            return
                        }
                        let ptrOutput = (ptrAddressOutput + MemoryLayout<Float>.stride * index).assumingMemoryBound(to: Float.self)
                        let ptrInitial = (ptrAddressInitial + MemoryLayout<Float>.stride * index).assumingMemoryBound(to: Float.self)
                        let ptrFinal = (ptrAddressFinal + MemoryLayout<Float>.stride * index).assumingMemoryBound(to: Float.self)
                        
                        // Interpolate
                        ptrOutput.pointee = (ptrFinal.pointee - ptrInitial.pointee) * progress + ptrInitial.pointee
                    }
                }
            }
        }
        return atomRadii
    }
}
