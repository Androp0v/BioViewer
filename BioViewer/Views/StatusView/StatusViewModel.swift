//
//  StatusViewModel.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 30/10/21.
//

import Foundation
import QuartzCore

enum StatusAction {
    case importFile
    case geometryGeneration
}

@MainActor class StatusViewModel: ObservableObject {
    
    weak var proteinViewModel: ProteinViewModel?
    
    // MARK: - UI properties
    // Published variables used by the UI
    @Published private(set) var statusText: String = NSLocalizedString("Idle", comment: "")
    @Published private(set) var statusRunning: Bool = false
    @Published private(set) var progress: Float?
    
    // Warning/Error system
    @Published private(set) var statusError: String?
    @Published private(set) var statusWarning: [String] = []
    
    // MARK: - Error types
    private(set) var importError: ImportError? {
        didSet {
            guard let importError = importError else {
                return
            }
            self.statusError = importError.localizedDescription
        }
    }
    
    // MARK: - Internal properties
    // Internal variables that do not instantly trigger a UI redraw
    private var displayLink: CADisplayLink?
    private var internalStatusText: String = NSLocalizedString("Idle", comment: "")
    private var internalProgress: Float?
    private var internalStatusWarning: [String] = []
    
    // MARK: - Functions
    @objc private func syncInternalAndUIStates() {
        statusText = internalStatusText
        progress = internalProgress
        statusWarning = internalStatusWarning
    }
    
    func setStatusText(text: String) {
        self.internalStatusText = text
    }
    
    func setRunningStatus(running: Bool) {
        DispatchQueue.main.async {
            self.statusRunning = running
            if running {
                let displayLink = CADisplayLink(target: self, selector: #selector(self.syncInternalAndUIStates))
                displayLink.add(to: .current, forMode: .default)
                self.displayLink = displayLink
            } else {
                self.internalStatusText = NSLocalizedString("Idle", comment: "")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    self.displayLink?.invalidate()
                })
            }
        }
    }
    
    func setProgress(progress: Float) {
        self.internalProgress = progress
    }
    
    func setImportError(error: ImportError) {
        self.importError = error
    }
    
    func removeImportError() {
        self.importError = nil
        // FIXME: Handle different error types
        self.statusError = nil
    }
    
    func setWarning(warning: String) {
        guard internalStatusWarning.count < AppState.maxNumberOfWarnings else { return }
        self.internalStatusWarning.append(warning)
    }
    
    func removeAllWarnings() {
        self.internalStatusWarning = []
        self.statusWarning = []
    }
    
    func removeAllErrors() {
        self.statusError = nil
    }
    
    // MARK: - Status handling

    func statusUpdate(statusText: String) {
        self.setStatusText(text: statusText)
        self.setRunningStatus(running: true)
    }

    func statusProgress(progress: Float) {
        self.setProgress(progress: progress)
    }

    func statusFinished(action: StatusAction) {
        self.setProgress(progress: 0)
        self.setRunningStatus(running: false)
        switch action {
        case .importFile:
            self.removeImportError()
        case .geometryGeneration:
            // TO-DO
            break
        }
    }
    
    func statusFinished(importError: ImportError) {
        self.setProgress(progress: 0)
        self.setRunningStatus(running: false)
        self.setImportError(error: importError)
    }
    
    func statusWarning(warningText: String) {
        
    }
}
