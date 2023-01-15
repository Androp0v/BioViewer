//
//  CartoonModel.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 14/1/23.
//

import Foundation

protocol CartoonModel {
    /// The type of cartoon structure (helix, sheet or loop).
    var type: CartoonStructureType { get }
    /// Positions of the alpha-carbons that define the backbone of the structure.
    var backbone: [simd_float3] { get }
}
