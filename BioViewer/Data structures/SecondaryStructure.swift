//
//  SecondaryStructure.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 5/3/23.
//

import Foundation

enum SecondaryStructure: UInt8, CaseIterable {
    case helix
    case sheet
    case loop
    case nonChain
}
