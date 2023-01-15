//
//  CartoonHelix.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 14/1/23.
//

import Foundation

class CartoonHelix: CartoonModel {
    /// The type of cartoon structure (helix, sheet or loop).
    let type: CartoonStructureType = .helix
    /// Positions of the alpha-carbons that define the backbone of the helix.
    var backbone: [simd_float3]
    
    init(backbone: [simd_float3]) {
        self.backbone = backbone
    }
}
