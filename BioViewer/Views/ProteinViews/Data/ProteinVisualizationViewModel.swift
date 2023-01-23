//
//  ProteinVisualizationViewModel.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/1/23.
//

import Foundation

class ProteinVisualizationViewModel: ObservableObject {
    
    weak var proteinViewModel: ProteinViewModel!
    
    /// Shared reference to the VisualizationBufferLoader class so it can be easily cancelled for subsequent calls..
    var visualizationBufferLoader = VisualizationBufferLoader()
    
    /// Visualization option for protein representation.
    @Published var visualization: ProteinVisualizationOption = .solidSpheres {
        didSet {
            visualizationBufferLoader.handleVisualizationChange(
                visualization: visualization,
                proteinViewModel: self.proteinViewModel
            )
        }
    }
    
    /// Radius option for solid spheres.
    @Published var solidSpheresRadiusOption: SolidSpheresRadiusOptions = .vanDerWaals {
        didSet {
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let self = self else { return }
                self.visualizationBufferLoader.handleVisualizationChange(
                    visualization: self.visualization,
                    proteinViewModel: self.proteinViewModel
                )
            }
        }
    }
    @Published var solidSpheresFixedAtomRadii: Float = 1.0 {
        didSet {
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let self = self else { return }
                self.visualizationBufferLoader.handleVisualizationChange(
                    visualization: self.visualization,
                    proteinViewModel: self.proteinViewModel
                )
            }
        }
    }
    @Published var solidSpheresVDWScale: Float = 1.0 {
        didSet {
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let self = self else { return }
                self.visualizationBufferLoader.handleVisualizationChange(
                    visualization: self.visualization,
                    proteinViewModel: self.proteinViewModel
                )
            }
        }
    }
    
    /// Radius option for ball and stick.
    @Published var ballAndStickRadiusOption: BallAndStickRadiusOptions = .fixed {
        didSet {
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let self = self else { return }
                self.visualizationBufferLoader.handleVisualizationChange(
                    visualization: self.visualization,
                    proteinViewModel: self.proteinViewModel
                )
            }
        }
    }
    @Published var ballAndSticksFixedAtomRadii: Float = 0.4 {
        didSet {
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let self = self else { return }
                self.visualizationBufferLoader.handleVisualizationChange(
                    visualization: self.visualization,
                    proteinViewModel: self.proteinViewModel
                )
            }
        }
    }
    @Published var ballAndSticksVDWScale: Float = 0.3 {
        didSet {
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let self = self else { return }
                self.visualizationBufferLoader.handleVisualizationChange(
                    visualization: self.visualization,
                    proteinViewModel: self.proteinViewModel
                )
            }
        }
    }
        
    /// Whether to show the structure surface..
    @Published var showSurface: Bool = false {
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
                    proteinViewModel.renderer.setDebugPointsBuffer(vertexBuffer: &debugBuffer)
                    #endif
                }
            }
        }
    }
    
    /// Scene's main camera focal length.
    @Published var cameraFocalLength: Float = 200 {
        didSet {
            proteinViewModel.renderer.scene.camera.updateFocalLength(
                focalLength: cameraFocalLength,
                aspectRatio: proteinViewModel.renderer.scene.aspectRatio
            )
        }
    }
}
