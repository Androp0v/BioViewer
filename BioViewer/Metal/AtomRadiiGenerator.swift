//
//  AtomRadiiGenerator.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/1/22.
//

import Foundation
import CoreAudio

class AtomRadiiGenerator {
        
    static func vanDerWaalsRadii(scale: Float = 1.0) -> AtomRadii {
        var atomRadii = AtomRadii()
        
        // WORKAROUND: C arrays with fixed sizes, such as the ones defined in FillColorInput, are
        // imported in Swift as tuples. To access its contents, we must use an unsafe pointer.
        withUnsafeMutableBytes(of: &atomRadii.atomRadius) { rawPtr -> Void in
            for index in 0..<Int(ATOM_TYPE_COUNT) {
                guard let ptrAddress = rawPtr.baseAddress else {
                    return
                }
                let ptr = (ptrAddress + MemoryLayout<Float>.stride * index).assumingMemoryBound(to: Float.self)
                ptr.pointee = AtomTypeUtilities.getAtomicVanDerWaalsRadius(atomType: UInt16(index)) * scale
            }
        }
        
        return atomRadii
    }
    
    static func fixedRadii(radius: Float = 0.4) -> AtomRadii {
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
    
    static func interpolatedRadii(initial: AtomRadii, final: AtomRadii, progress: Float) -> AtomRadii {
        var atomRadii = AtomRadii()
        var initial = initial
        var final = final
        
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
