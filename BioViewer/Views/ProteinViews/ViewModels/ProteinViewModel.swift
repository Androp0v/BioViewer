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

    @Published var renderer: ProteinRenderer
    @Published var backgroundColor: Color = .black {
        didSet {
            guard let newCGColor = backgroundColor.cgColor else { return }
            renderer.scene.backgroundColor = newCGColor
        }
    }
    @Published var cameraFocalLength: Float = 200 {
        didSet {
            renderer.scene.camera.updateFocalLength(focalLength: cameraFocalLength,
                                                    aspectRatio: renderer.scene.aspectRatio)
        }
    }

    @Published var dataSource: ProteinViewDataSource

    let dropDelegate: ImportDroppedFilesDelegate

    // Reference to the status view model for updates
    var statusViewModel: StatusViewModel

    @Published var proteinCount: Int = 0
    @Published var totalAtomCount: Int = 0

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
        self.dropDelegate = ImportDroppedFilesDelegate()

        // Setup view status
        self.statusViewModel = StatusViewModel()

        // Pass reference to ProteinViewModel to delegates and datasources
        self.dataSource.proteinViewModel = self
        self.dropDelegate.proteinViewModel = self
    }

    // MARK: - Public functions

    func removeAllProteins() {
        self.dataSource.removeAllProteinsFromDatasource()
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

    func statusFinished() {
        self.statusViewModel.setProgress(progress: 0)
        self.statusViewModel.setRunningStatus(running: false)
    }
    
    func statusFinished(withError: String) {
        self.statusViewModel.setProgress(progress: 0)
        self.statusViewModel.setRunningStatus(running: false)
        self.statusViewModel.setError(error: withError)
    }
    
    func statusWarning(warningText: String) {
        
    }
}
