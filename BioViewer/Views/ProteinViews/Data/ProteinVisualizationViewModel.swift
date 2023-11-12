//
//  ProteinVisualizationViewModel.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/1/23.
//

import Foundation

@MainActor @Observable class ProteinVisualizationViewModel {
    
    weak var proteinViewModel: ProteinViewModel!
    
    /// Shared reference to the VisualizationBufferLoader class so it can be easily cancelled for subsequent calls..
    var visualizationBufferLoader = VisualizationBufferLoader()
    
    /// Visualization option for protein representation.
    var visualization: ProteinVisualizationOption = .solidSpheres {
        didSet {
            visualizationBufferLoader.handleVisualizationChange(
                visualization: visualization,
                proteinViewModel: self.proteinViewModel
            )
        }
    }
    
    /// Radius option for solid spheres.
    var solidSpheresRadiusOption: SolidSpheresRadiusOptions = .vanDerWaals {
        didSet {
            self.visualizationBufferLoader.handleVisualizationChange(
                visualization: self.visualization,
                proteinViewModel: self.proteinViewModel
            )
        }
    }
    var solidSpheresFixedAtomRadii: Float = 1.0 {
        didSet {
            self.visualizationBufferLoader.handleVisualizationChange(
                visualization: self.visualization,
                proteinViewModel: self.proteinViewModel
            )
        }
    }
    var solidSpheresVDWScale: Float = 1.0 {
        didSet {
            self.visualizationBufferLoader.handleVisualizationChange(
                visualization: self.visualization,
                proteinViewModel: self.proteinViewModel
            )
        }
    }
    
    /// Radius option for ball and stick.
    var ballAndStickRadiusOption: BallAndStickRadiusOptions = .fixed {
        didSet {
            self.visualizationBufferLoader.handleVisualizationChange(
                visualization: self.visualization,
                proteinViewModel: self.proteinViewModel
            )
        }
    }
    var ballAndSticksFixedAtomRadii: Float = 0.4 {
        didSet {
            self.visualizationBufferLoader.handleVisualizationChange(
                visualization: self.visualization,
                proteinViewModel: self.proteinViewModel
            )
        }
    }
    var ballAndSticksVDWScale: Float = 0.3 {
        didSet {
            self.visualizationBufferLoader.handleVisualizationChange(
                visualization: self.visualization,
                proteinViewModel: self.proteinViewModel
            )
        }
    }
        
    /// Whether to show the structure surface..
    var showSurface: Bool = false {
        didSet {
            if showSurface {
                Task {
                    guard let proteinViewModel = self.proteinViewModel,
                          let dataSource = proteinViewModel.dataSource
                    else { return }
                    guard var debugBuffer = ComputeMolecularSurfaceUtility(protein: (dataSource.files.first?.models.first)!)
                            .createMolecularSurface() else {
                        return
                    }
                    #if DEBUG
                    await proteinViewModel.renderer.mutableState.setDebugPointsBuffer(vertexBuffer: &debugBuffer)
                    #endif
                }
            }
        }
    }
    
    /// Scene's main camera focal length.
    var cameraFocalLength: Float = 200 {
        didSet {
            Task {
                await proteinViewModel.renderer.mutableState.setCameraFocalLength(
                    cameraFocalLength
                )
            }
        }
    }
}
