//
//  AtomRadiiGenerator.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/1/22.
//

import Foundation

class AtomRadiiGenerator {
    
    static func createAtomRadii(radii: [Float]) -> AtomRadii {
        guard radii.count >= 6 else {
            NSLog("Not enough atom sizes specified to create an atom radii configuration, defaulting to Van der Waals radii.")
            return vanDerWaalsRadii()
        }
        var atomRadii = AtomRadii()
        atomRadii.atomRadius.0 = radii[0]
        atomRadii.atomRadius.1 = radii[1]
        atomRadii.atomRadius.2 = radii[2]
        atomRadii.atomRadius.3 = radii[3]
        atomRadii.atomRadius.4 = radii[4]
        atomRadii.atomRadius.5 = radii[5]
        
        return atomRadii
    }
    
    static func vanDerWaalsRadii() -> AtomRadii {
        var atomRadii = AtomRadii()
        // C, H, N, O, S, Others
        atomRadii.atomRadius.0 = 1.70
        atomRadii.atomRadius.1 = 1.10
        atomRadii.atomRadius.2 = 1.55
        atomRadii.atomRadius.3 = 1.52
        atomRadii.atomRadius.4 = 1.80
        atomRadii.atomRadius.5 = 1.50
        
        return atomRadii
    }
    
    static func fixedRadii(radius: Float = 0.4) -> AtomRadii {
        var atomRadii = AtomRadii()
        // C, H, N, O, S, Others
        atomRadii.atomRadius.0 = radius
        atomRadii.atomRadius.1 = radius
        atomRadii.atomRadius.2 = radius
        atomRadii.atomRadius.3 = radius
        atomRadii.atomRadius.4 = radius
        atomRadii.atomRadius.5 = radius
        
        return atomRadii
    }
}
