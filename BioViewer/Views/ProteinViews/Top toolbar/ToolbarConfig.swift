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

@MainActor class ToolbarConfig: ObservableObject {
    
    weak var proteinViewModel: ProteinViewModel?
    
    // MARK: - Properties
    
    @Published var selectedTool: Int = CameraControlTool.rotate
    
    @Published var autorotating: Bool = false {
        didSet {
            Task {
                await proteinViewModel?.renderer.mutableState.setAutorotating(autorotating)
            }
        }
    }
    
    // MARK: - Actions
    
    func resetCamera() {
        Task {
            await proteinViewModel?.renderer.mutableState.resetCamera()
        }
    }
}
