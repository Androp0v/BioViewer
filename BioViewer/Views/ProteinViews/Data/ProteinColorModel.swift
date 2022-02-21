//
//  ColorScene.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 25/11/21.
//

import Foundation
import simd
import SwiftUI

public enum ProteinColorByOption {
    static let none: Int = -1
    static let element: Int = 0
    static let subunit: Int = 1
}

extension ProteinViewModel {
        
    func initElementColors() {
        // Preselected element color palette, C, H, N, O, S, Unknown
        elementColors =
            [
                Color(.displayP3, red: 0.423, green: 0.733, blue: 0.235, opacity: 1.0),
                Color(.displayP3, red: 1.000, green: 1.000, blue: 1.000, opacity: 1.0),
                Color(.displayP3, red: 0.091, green: 0.148, blue: 0.556, opacity: 1.0),
                Color(.displayP3, red: 1.000, green: 0.149, blue: 0.000, opacity: 1.0),
                Color(.displayP3, red: 1.000, green: 0.780, blue: 0.349, opacity: 1.0),
                Color(.displayP3, red: 0.517, green: 0.517, blue: 0.517, opacity: 1.0)
            ]
    }
    
    func initSubunitColors() {
        subunitColors = []
        // Preselected color palette
        let fixedColorPalette =
            [
                Color(.displayP3, red: 0/255, green: 177/255, blue: 228/255, opacity: 1),
                Color(.displayP3, red: 199/255, green: 0/255, blue: 156/255, opacity: 1),
                Color(.displayP3, red: 194/255, green: 104/255, blue: 1/255, opacity: 1),
                Color(.displayP3, red: 27/255, green: 170/255, blue: 0/255, opacity: 1),
                Color(.displayP3, red: 0.917, green: 0.085, blue: 0.183, opacity: 1),
                Color(.displayP3, red: 0.225, green: 0.129, blue: 0.650, opacity: 1),
                Color(.displayP3, red: 0.894, green: 0.682, blue: 0.203, opacity: 1),
                Color(.displayP3, red: 0.216, green: 0.945, blue: 0.657, opacity: 1)
            ]
        for index in 0..<fixedColorPalette.count {
            guard index < MAX_ATOM_COLORS else { return }
            subunitColors.append(fixedColorPalette[index])
        }
        // If there are more subunits than colors in the preselected color palette, chose them
        // at random.
        for _ in fixedColorPalette.count..<Int(MAX_ATOM_COLORS) {
            subunitColors.append(randomColor())
        }
    }
    
    // MARK: - Utility functions
    
    private func randomColor() -> Color {
        let red = CGFloat.random(in: 0..<1)
        let green = CGFloat.random(in: 0..<1)
        let blue = CGFloat.random(in: 0..<1)
        return Color(cgColor: CGColor(red: red, green: green, blue: blue, alpha: 1.0))
    }
}
