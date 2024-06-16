//
//  ToolbarConfig.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 19/12/21.
//

import Foundation

enum CameraControlTool {
    static let rotate: Int = 0
    static let move: Int = 1
}

@MainActor @Observable class ToolbarConfig {
    
    weak var proteinViewModel: ProteinViewModel?
    
    // MARK: - Properties
    
    var selectedTool: Int = CameraControlTool.rotate
    
    var autorotating: Bool = false {
        didSet {
            Task {
                await proteinViewModel?.renderer.setAutorotating(autorotating)
            }
        }
    }
    
    // MARK: - Actions
    
    func resetCamera() {
        Task {
            await proteinViewModel?.renderer.resetCamera()
        }
    }
}
