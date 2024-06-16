//
//  ProteinViewModel.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 13/5/21.
//

import Combine
import Foundation
import SwiftUI

final class ProteinViewModel: Sendable {

    // MARK: - Properties
    
    /// Metal rendering engine.
    let renderer: ProteinRenderer
    /// Datasource to hold actual protein data.
    let dataSource: ProteinDataSource
    /// Linked ProteinColorViewModel
    let colorViewModel: ProteinColorViewModel
    /// Linked ProteinVisualizationViewModel
    let visualizationViewModel: ProteinVisualizationViewModel
    /// Toolbar view model.
    let toolbarConfig: ToolbarConfig
    /// Reference to the status view model for updates.
    let statusViewModel: StatusViewModel
    /// Delegate to handle dropped files in view.
    let dropHandler: ImportDroppedFilesDelegate
    
    // MARK: - Initialization

    @MainActor init(isBenchmark: Bool = false) {
        // Setup Metal renderer
        self.renderer = ProteinRenderer(isBenchmark: isBenchmark)
        
        self.dataSource = ProteinDataSource()
        self.colorViewModel = ProteinColorViewModel()
        self.visualizationViewModel = ProteinVisualizationViewModel()
        self.toolbarConfig = ToolbarConfig()
        self.dropHandler = ImportDroppedFilesDelegate()
        self.statusViewModel = StatusViewModel()
        
        setup()
    }
    
    @MainActor private func setup() {
        self.dataSource.proteinViewModel = self
        self.colorViewModel.proteinViewModel = self
        self.visualizationViewModel.proteinViewModel = self
        self.toolbarConfig.proteinViewModel = self
        self.dropHandler.proteinViewModel = self
    }

    // MARK: - Public functions

    func removeAllFiles() async {
        await self.dataSource.removeAllFilesFromDatasource()
        // FIXME: Status changes, self.statusViewModel?.removeAllWarnings()
        // FIXME: Status changes, self.statusViewModel?.removeAllErrors()
    }
}
