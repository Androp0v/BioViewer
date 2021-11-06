//
//  StatusViewModel.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 30/10/21.
//

import Foundation
import QuartzCore

class StatusViewModel: ObservableObject {
    
    // Published variables used by the UI
    @Published private(set) var statusText: String = NSLocalizedString("Idle", comment: "")
    @Published private(set) var statusRunning: Bool = false
    @Published private(set) var progress: Float?
        
    // Internal variables that do not instantly trigger a UI redraw
    private var displayLink: CADisplayLink?
    private var internalStatusText: String = NSLocalizedString("Idle", comment: "")
    private var internalProgress: Float?
    
    @objc private func syncInternalAndUIStates() {
        statusText = internalStatusText
        progress = internalProgress
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
}
