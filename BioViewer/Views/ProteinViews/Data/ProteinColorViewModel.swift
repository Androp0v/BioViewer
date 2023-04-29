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
            Task {
                await proteinViewModel?.renderer.mutableState.scene.colorFill = updatedFillColor()
            }
        }
    }
    
    /// Scene background color.
    @Published var backgroundColor: Color = .black {
        didSet {
            guard let newCGColor = backgroundColor.cgColor else { return }
            Task {
                await proteinViewModel?.renderer.mutableState.scene.backgroundColor = newCGColor
            }
        }
    }
    
    /// What kind of color scheme is used to color atoms (i.e. by element or by chain).
    @Published var colorBy: ProteinColorByOption {
        didSet {
            guard let renderer = proteinViewModel?.renderer else { return }
            Task {
                await renderer.mutableState.scene.animator?.animatedFillColorChange(
                    initialColors: renderer.mutableState.scene.colorFill,
                    finalColors: updatedFillColor(),
                    duration: 0.15
                )
            }
        }
    }
    
    /// Color used for each element when coloring by element.
    @Published var elementColors: [Color] = [Color]() {
        didSet {
            Task {
                await proteinViewModel?.renderer.mutableState.scene.colorFill = updatedFillColor()
            }
        }
    }
    
    /// Color used for each subunit when coloring by subunit.
    @Published var subunitColors: [Color] = [Color]() {
        didSet {
            Task {
                await proteinViewModel?.renderer.mutableState.scene.colorFill = updatedFillColor()
            }
        }
    }
    
    /// Color used for each residue when coloring by residue.
    @Published var residueColors: [Color] = [Color]() {
        didSet {
            Task {
                await proteinViewModel?.renderer.mutableState.scene.colorFill = updatedFillColor()
            }
        }
    }
    
    /// Color used for each residue when coloring by residue.
    @Published var structureColors: [Color] = [Color]() {
        didSet {
            Task {
                await proteinViewModel?.renderer.mutableState.scene.colorFill = updatedFillColor()
            }
        }
    }
    
    /// Color used for each subunit when coloring by element.
    @Published var bondColor: Color = .gray {
        didSet {
            // TODO: Animation
            if let newColor = bondColor.cgColor {
                Task {
                    await proteinViewModel?.renderer.mutableState.scene.bondColor = newColor
                }
            }
        }
    }
    
    // MARK: - Init
    
    init() {
        
        // Setup coloring scheme
        self.colorBy = .element
        
        // Initialize colors
        initElementColors()
        initSubunitColors()
        initResidueColors()
        initStructureColors()
    }
}
