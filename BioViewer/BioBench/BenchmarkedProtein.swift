//
//  BenchmarkedProtein.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 12/11/23.
//

import Foundation

struct BenchmarkedProtein: Equatable, Identifiable, Sendable {
    let id = UUID()
    let name: String
    let atoms: Int
    let time: Double
    let std: (Double, Double)
    
    static func == (lhs: BenchmarkedProtein, rhs: BenchmarkedProtein) -> Bool {
        return lhs.id == rhs.id
    }
}
