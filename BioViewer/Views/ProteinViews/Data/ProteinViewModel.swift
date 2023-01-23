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
    var renderer: ProteinRenderer
    /// Datasource to hold actual protein data.
    var dataSource: ProteinDataSource?
    /// Linked ProteinColorViewModel
    var colorViewModel: ProteinColorViewModel?
    /// Linked ProteinVisualizationViewModel
    var visualizationViewModel: ProteinVisualizationViewModel?
    /// Toolbar view model.
    var toolbarConfig: ToolbarConfig?
    
    /// Delegate to handle dropped files in view.
    var dropHandler: ImportDroppedFilesDelegate
    /// Reference to the status view model for updates.
    var statusViewModel: StatusViewModel
    
    // MARK: - Initialization

    init() {
        // Setup Metal renderer
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Unable to create default Metal Device")
        }
        self.renderer = ProteinRenderer(device: device)

        // Setup drop delegate
        self.dropHandler = ImportDroppedFilesDelegate()

        // Setup view status
        self.statusViewModel = StatusViewModel()

        // Pass reference to ProteinViewModel to delegates and datasources
        self.dropHandler.proteinViewModel = self
        
        // Add the dataSource to the renderer
        self.renderer.proteinDataSource = dataSource
    }

    // MARK: - Public functions

    func removeAllFiles() {
        self.dataSource?.removeAllFilesFromDatasource()
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
