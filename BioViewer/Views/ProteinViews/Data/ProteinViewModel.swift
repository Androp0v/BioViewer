//
//  ProteinViewModel.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 13/5/21.
//

import Combine
import Foundation
import SwiftUI

@MainActor class ProteinViewModel: ObservableObject {

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
    /// Reference to the status view model for updates.
    var statusViewModel: StatusViewModel?
    
    /// Delegate to handle dropped files in view.
    var dropHandler: ImportDroppedFilesDelegate
    
    // MARK: - Initialization

    init(isBenchmark: Bool = false) {
        // Setup Metal renderer
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Unable to create default Metal Device")
        }
        self.renderer = ProteinRenderer(device: device, isBenchmark: isBenchmark)

        // Setup drop delegate
        self.dropHandler = ImportDroppedFilesDelegate()
        
        // Pass reference to ProteinViewModel to delegates and datasources
        self.dropHandler.proteinViewModel = self
        
        // Add the dataSource to the renderer
        self.renderer.proteinDataSource = dataSource
    }

    // MARK: - Public functions

    func removeAllFiles() async {
        await self.dataSource?.removeAllFilesFromDatasource()
        // FIXME: Status changes, self.statusViewModel?.removeAllWarnings()
        // FIXME: Status changes, self.statusViewModel?.removeAllErrors()
    }
}
