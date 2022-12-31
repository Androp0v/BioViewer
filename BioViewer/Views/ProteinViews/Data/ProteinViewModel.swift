//
//  ProteinViewModel.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 13/5/21.
//

import Combine
import Foundation
import SwiftUI

class ProteinViewModel: ObservableObject {

    // MARK: - Properties
    
    /// Metal rendering engine.
    @Published var renderer: ProteinRenderer
    /// Datasource to hold actual protein data.
    @Published var dataSource: ProteinViewDataSource
    /// Delegate to handle dropped files in view.
    var dropHandler: ImportDroppedFilesDelegate
    /// Reference to the status view model for updates.
    var statusViewModel: StatusViewModel
    /// Toolbar view model.
    @Published var toolbarConfig = ToolbarConfig()
    
    /// Total protein count in view.
    @Published var proteinCount: Int = 0
    /// Total subunit count in view.
    @Published var totalSubunitCount: Int = 0
    /// Total atom count in view.
    @Published var totalAtomCount: Int = 0
    
    // MARK: - Modified from the UI
    
    /// Scene background color.
    @Published var backgroundColor: Color = .black {
        didSet {
            guard let newCGColor = backgroundColor.cgColor else { return }
            renderer.scene.backgroundColor = newCGColor
        }
    }
    
    /// Shared reference to the VisualizationBufferLoader class so it can be easily cancelled for subsequent calls..
    var visualizationBufferLoader = VisualizationBufferLoader()
    
    /// Visualization option for protein representation.
    @Published var visualization: ProteinVisualizationOption = .solidSpheres {
        didSet {
            visualizationBufferLoader.handleVisualizationChange(visualization: visualization,
                                                                proteinViewModel: self)
        }
    }
    
    /// Radius option for solid spheres.
    @Published var solidSpheresRadiusOption: ProteinSolidSpheresRadiusOptions = .vanDerWaals {
        didSet {
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let self = self else { return }
                self.visualizationBufferLoader.handleVisualizationChange(visualization: self.visualization,
                                                                         proteinViewModel: self)
            }
        }
    }
    @Published var solidSpheresFixedAtomRadii: Float = 1.0 {
        didSet {
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let self = self else { return }
                self.visualizationBufferLoader.handleVisualizationChange(visualization: self.visualization,
                                                                         proteinViewModel: self)
            }
        }
    }
    @Published var solidSpheresVDWScale: Float = 1.0 {
        didSet {
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let self = self else { return }
                self.visualizationBufferLoader.handleVisualizationChange(visualization: self.visualization,
                                                                         proteinViewModel: self)
            }
        }
    }
    
    /// Radius option for ball and stick.
    @Published var ballAndStickRadiusOption: ProteinBallAndStickRadiusOptions = .fixed {
        didSet {
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let self = self else { return }
                self.visualizationBufferLoader.handleVisualizationChange(visualization: self.visualization,
                                                                         proteinViewModel: self)
            }
        }
    }
    @Published var ballAndSticksFixedAtomRadii: Float = 0.4 {
        didSet {
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let self = self else { return }
                self.visualizationBufferLoader.handleVisualizationChange(visualization: self.visualization,
                                                                         proteinViewModel: self)
            }
        }
    }
    @Published var ballAndSticksVDWScale: Float = 0.3 {
        didSet {
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let self = self else { return }
                self.visualizationBufferLoader.handleVisualizationChange(visualization: self.visualization,
                                                                         proteinViewModel: self)
            }
        }
    }
    
    /// What kind of color scheme is used to color atoms (i.e. by element or by chain).
    @Published var colorBy: Int {
        didSet {
            self.renderer.scene.animator?.animatedFillColorChange(initialColors: self.renderer.scene.colorFill,
                                                                  finalColors: updatedFillColor(),
                                                                  duration: 0.15)
        }
    }
    
    /// Color used for each subunit when coloring by element.
    @Published var bondColor: Color = .gray {
        didSet {
            // TODO: Animation
            if let newColor = bondColor.cgColor {
                self.renderer.scene.bondColor = newColor
            }
        }
    }
    
    /// Color used for each subunit when coloring by element.
    @Published var elementColors: [Color] = [Color]() {
        didSet {
            self.renderer.scene.colorFill = updatedFillColor()
        }
    }
    
    /// Color used for each subunit when coloring by subunit.
    @Published var subunitColors: [Color] = [Color]() {
        didSet {
            self.renderer.scene.colorFill = updatedFillColor()
        }
    }
        
    /// Whether to show the structure surface..
    @Published var showSurface: Bool = false {
        didSet {
            if showSurface {
                Task {
                    guard var debugBuffer = ComputeMolecularSurfaceUtility(protein: (dataSource.files.first?.models.first)!)
                            .createMolecularSurface() else {
                        return
                    }
                    #if DEBUG
                    renderer.setDebugPointsBuffer(vertexBuffer: &debugBuffer)
                    #endif
                }
            }
        }
    }
    
    /// Scene's main camera focal length.
    @Published var cameraFocalLength: Float = 200 {
        didSet {
            renderer.scene.camera.updateFocalLength(focalLength: cameraFocalLength,
                                                    aspectRatio: renderer.scene.aspectRatio)
        }
    }
    
    @Published var autorotating: Bool = false {
        didSet {
            renderer.scene.autorotating = autorotating
        }
    }
    
    // MARK: - Initialization

    init() {
        // Setup Metal renderer
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Unable to create default Metal Device")
        }
        self.renderer = ProteinRenderer(device: device)

        // Setup datasource
        let dataSource = ProteinViewDataSource()
        self.dataSource = dataSource

        // Setup drop delegate
        self.dropHandler = ImportDroppedFilesDelegate()

        // Setup view status
        self.statusViewModel = StatusViewModel()
        
        // Setup coloring scheme
        self.colorBy = ProteinColorByOption.element

        // Pass reference to ProteinViewModel to delegates and datasources
        self.dataSource.proteinViewModel = self
        self.dropHandler.proteinViewModel = self
        
        // Add the dataSource to the renderer
        self.renderer.proteinDataSource = dataSource
        
        // Initialize colors
        initElementColors()
        initSubunitColors()
        renderer.scene.colorFill = updatedFillColor()
    }

    // MARK: - Public functions

    func removeAllFiles() {
        self.dataSource.removeAllFilesFromDatasource()
        self.statusViewModel.removeAllWarnings()
        self.statusViewModel.removeAllErrors()
    }

    // MARK: - Status handling

    func statusUpdate(statusText: String) {
        self.statusViewModel.setStatusText(text: statusText)
        self.statusViewModel.setRunningStatus(running: true)
    }

    func statusProgress(progress: Float) {
        self.statusViewModel.setProgress(progress: progress)
    }

    func statusFinished(action: StatusAction) {
        self.statusViewModel.setProgress(progress: 0)
        self.statusViewModel.setRunningStatus(running: false)
        switch action {
        case .importFile:
            self.statusViewModel.removeImportError()
        case .geometryGeneration:
            // TO-DO
            break
        }
    }
    
    func statusFinished(importError: ImportError) {
        self.statusViewModel.setProgress(progress: 0)
        self.statusViewModel.setRunningStatus(running: false)
        self.statusViewModel.setImportError(error: importError)
    }
    
    func statusWarning(warningText: String) {
        
    }
}
