//
//  ProteinColorViewModel.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/1/23.
//

import Foundation
import SwiftUI

class ProteinColorViewModel: ObservableObject {
    
    weak var proteinViewModel: ProteinViewModel? {
        didSet {
            proteinViewModel?.renderer.scene.colorFill = updatedFillColor()
        }
    }
    
    /// Scene background color.
    @Published var backgroundColor: Color = .black {
        didSet {
            guard let newCGColor = backgroundColor.cgColor else { return }
            proteinViewModel?.renderer.scene.backgroundColor = newCGColor
        }
    }
    
    /// What kind of color scheme is used to color atoms (i.e. by element or by chain).
    @Published var colorBy: ProteinColorByOption {
        didSet {
            guard let renderer = proteinViewModel?.renderer else { return }
            renderer.scene.animator?.animatedFillColorChange(
                initialColors: renderer.scene.colorFill,
                finalColors: updatedFillColor(),
                duration: 0.15
            )
        }
    }
    
    /// Color used for each element when coloring by element.
    @Published var elementColors: [Color] = [Color]() {
        didSet {
            proteinViewModel?.renderer.scene.colorFill = updatedFillColor()
        }
    }
    
    /// Color used for each residue when coloring by residue.
    @Published var residueColors: [Color] = [Color]() {
        didSet {
            proteinViewModel?.renderer.scene.colorFill = updatedFillColor()
        }
    }
    
    /// Color used for each subunit when coloring by subunit.
    @Published var subunitColors: [Color] = [Color]() {
        didSet {
            proteinViewModel?.renderer.scene.colorFill = updatedFillColor()
        }
    }
    
    /// Color used for each subunit when coloring by element.
    @Published var bondColor: Color = .gray {
        didSet {
            // TODO: Animation
            if let newColor = bondColor.cgColor {
                proteinViewModel?.renderer.scene.bondColor = newColor
            }
        }
    }
    
    // MARK: - Init
    
    init() {
        
        // Setup coloring scheme
        self.colorBy = .element
        
        // Initialize colors
        initElementColors()
        initResidueColors()
        initSubunitColors()
    }
}
