//
//  StatusViewModel.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 30/10/21.
//

import Foundation
import QuartzCore
import SwiftUI

enum StatusActionType {
    case importFile
    case geometryGeneration
    
    var title: String {
        switch self {
        case .importFile:
            return "Import file"
        case .geometryGeneration:
            return "Ball and stick"
        }
    }
}

struct StatusAction: Identifiable {
    let id = UUID()
    let type: StatusActionType
    var description: String?
    var progress: Double?
}

@MainActor class StatusViewModel: ObservableObject {
    
    weak var proteinViewModel: ProteinViewModel?
    
    // MARK: - UI properties
    // Published variables used by the UI
    @Published private(set) var runningActions = [StatusAction]()
    
    var isImportingFile: Bool {
        return runningActions.contains(where: {$0.type == .importFile})
    }
    
    // Warning/Error system
    /*
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
     */
    
    // MARK: - Internal properties
    // Internal variables that do not instantly trigger a UI redraw
    private var displayLink: CADisplayLink?
    private var internalRunningActions = [StatusAction]()
    /*
    private var internalStatusText: String?
    private var internalProgress: Float?
    private var internalStatusWarning: [String] = []
     */
    
    // MARK: - Init
    
    init() {
        let displayLink = CADisplayLink(target: self, selector: #selector(self.syncInternalAndUIStates))
        displayLink.add(to: .main, forMode: .default)
        self.displayLink = displayLink
    }
    
    // MARK: - Functions
    @objc private func syncInternalAndUIStates() {
        withAnimation {
            runningActions = internalRunningActions
        }
    }
    
    func showStatusForAction(_ statusAction: StatusAction) {
        internalRunningActions.append(statusAction)
    }
    
    func updateDescription(_ statusAction: StatusAction, description: String?) {
        guard internalRunningActions.contains(where: {$0.id == statusAction.id}) else {
            print("[Status] Error: update action not found.")
            return
        }
        internalRunningActions.removeAll(where: { $0.id == statusAction.id })
        var newAction = statusAction
        newAction.description = description
        internalRunningActions.append(newAction)
    }
    
    func updateProgress(_ statusAction: StatusAction, progress: Double?) {
        guard internalRunningActions.contains(where: {$0.id == statusAction.id}) else {
            print("[Status] Error: update action not found.")
            return
        }
        internalRunningActions.removeAll(where: { $0.id == statusAction.id })
        var newAction = statusAction
        newAction.progress = progress
        internalRunningActions.append(newAction)
    }
    
    func signalActionFinished(_ statusAction: StatusAction, withError: Error?) {
        guard internalRunningActions.contains(where: {$0.id == statusAction.id}) else {
            print("[Status] Error: finished action not found.")
            return
        }
        internalRunningActions.removeAll(where: { $0.id == statusAction.id })
    }
    
    /*

    func setStatusText(text: String) {
        self.internalStatusText = text
    }
    
    func setRunningStatus(running: Bool) {
        DispatchQueue.main.async {
            self.statusRunning = running
            if running {
                let displayLink = CADisplayLink(target: self, selector: #selector(self.syncInternalAndUIStates))
                displayLink.add(to: .main, forMode: .default)
                self.displayLink = displayLink
            } else {
                self.internalStatusText = nil
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

    func statusFinished(action: StatusActionType) {
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
     */
}
