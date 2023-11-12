//
//  ParsedConfiguration.swift
//
//
//  Created by Raúl Montón Pinillos on 12/11/23.
//

import BioViewerFoundation
import Foundation
import simd

class XYZParsedConfiguration {
    var id: Int
    var energy: Float?
    // Make one atom array per common element
    var carbonArray = [simd_float3]()
    var nitrogenArray = [simd_float3]()
    var hydrogenArray = [simd_float3]()
    var oxygenArray = [simd_float3]()
    var sulfurArray = [simd_float3]()
    var othersArray = [simd_float3]()
    var atomElements = [AtomElement]()
    var atomArrayComposition = ProteinElementComposition()
            
    init(id: Int) {
        self.id = id
    }
}
