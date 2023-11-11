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
    
    var blocksRendering: Bool {
        switch self {
        case .importFile:
            true
        case .geometryGeneration:
            false
        }
    }
}

struct StatusAction: Identifiable {
    let id = UUID()
    let type: StatusActionType
    var description: String?
    var progress: Double?
    var error: Error?
}

@MainActor class StatusViewModel: ObservableObject {
    
    weak var proteinViewModel: ProteinViewModel?
    
    // MARK: - UI properties
    // Published variables used by the UI
    @Published private(set) var actionToShow: StatusAction?
    @Published private(set) var runningActions = [StatusAction]()
    @Published private(set) var failedActions = [StatusAction]()
    
    var isBlockingUI: Bool {
        if runningActions.contains(where: {$0.type.blocksRendering}) {
            return true
        } else if failedActions.contains(where: {$0.type.blocksRendering}) {
            return true
        }
        return false
    }
    var isImportingFile: Bool {
        if runningActions.contains(where: {$0.type == .importFile}) {
            return true
        } else if failedActions.contains(where: {$0.type == .importFile}) {
            return true
        }
        return false
    }
    
    // MARK: - Internal properties
    // Internal variables that do not instantly trigger a UI redraw
    private var displayLink: CADisplayLink?
    private var internalRunningActions = [StatusAction]()
    private var internalFailedActions = [StatusAction]()
    
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
            failedActions = internalFailedActions
            actionToShow = failedActions.last ?? runningActions.last
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
    
    func signalActionFinished(_ statusAction: StatusAction, withError error: Error?) {
        guard internalRunningActions.contains(where: {$0.id == statusAction.id}) else {
            print("[Status] Error: finished action not found.")
            return
        }
        internalRunningActions.removeAll(where: { $0.id == statusAction.id })
        if let error {
            var newAction = statusAction
            newAction.error = error
            internalFailedActions.append(newAction)
        }
    }
    
    func dismissAction(_ statusAction: StatusAction) {
        internalRunningActions.removeAll(where: { $0.id == statusAction.id })
        internalFailedActions.removeAll(where: { $0.id == statusAction.id })
    }
}
