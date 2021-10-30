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

    @Published var metalRenderer: ProteinRenderer
    @Published var backgroundColor: Color = .black {
        didSet {
            guard let newCGColor = backgroundColor.cgColor else { return }
            metalRenderer.scene.backgroundColor = newCGColor
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
        self.metalRenderer = ProteinRenderer(device: device)

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
        // TO-DO
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
        self.statusViewModel.setStatusText(text: "Idle")
        self.statusViewModel.setRunningStatus(running: false)
        self.statusViewModel.setProgress(progress: 0)
    }
}
