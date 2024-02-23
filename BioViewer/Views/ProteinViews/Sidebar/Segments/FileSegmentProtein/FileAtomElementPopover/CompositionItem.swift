//
//  CompositionItem.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 22/1/23.
//

import Charts
import Foundation
import SwiftUI

struct CompositionItem: Hashable, Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let count: Int
    let fraction: Double
}
