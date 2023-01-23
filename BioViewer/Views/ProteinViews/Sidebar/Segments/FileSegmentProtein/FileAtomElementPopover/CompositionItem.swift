//
//  CompositionItem.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 22/1/23.
//

import Foundation
import SwiftUI

struct CompositionItem: Hashable {
    let id = UUID()
    let name: String
    let color: Color
    let count: Int
    let fraction: Double
}