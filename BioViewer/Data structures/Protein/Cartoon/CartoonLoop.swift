//
//  CartoonLoop.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 14/1/23.
//

import Foundation

class CartoonLoop: CartoonModel {
    /// The type of cartoon structure (helix, sheet or loop).
    let type: CartoonStructureType = .loop
    /// Positions of the alpha-carbons that define the backbone of the loop.
    var backbone: [simd_float3]
    
    init(backbone: [simd_float3]) {
        self.backbone = backbone
    }
}
