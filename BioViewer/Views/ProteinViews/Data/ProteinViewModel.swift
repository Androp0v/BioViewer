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
        
    /// Whether to show the structure surface..
    @Published var showSurface: Bool = false {
        didSet {
            // TO-DO
        }
    }
    
    /// Scene's main camera focal length.
    @Published var cameraFocalLength: Float = 200 {
        didSet {
            renderer.scene.camera.updateFocalLength(focalLength: cameraFocalLength,
                                                    aspectRatio: renderer.scene.aspectRatio)
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

        // Pass reference to ProteinViewModel to delegates and datasources
        self.dataSource.proteinViewModel = self
        self.dropHandler.proteinViewModel = self
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
