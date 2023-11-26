//
//  VisualizationScene.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 31/12/21.
//

import BioViewerFoundation
import Foundation
import SwiftUI

class VisualizationBufferLoader {
    
    // MARK: - Handle visualization
    
    var currentTask: Task<Void, Never>?
    weak var proteinViewModel: ProteinViewModel?
    
    @MainActor func handleVisualizationChange(
        visualization: ProteinVisualizationOption,
        proteinViewModel: ProteinViewModel
    ) {
        
        // Save reference to proteinViewModel
        self.proteinViewModel = proteinViewModel
        
        // Cancel previously running visualization handling task (if any)
        currentTask?.cancel()
        
        // Add a new geometry creation task
        currentTask = Task {
            // Compute model connectivity if not already present
            if visualization == .ballAndStick {
                guard let dataSource = proteinViewModel.dataSource,
                      let protein = dataSource.getFirstProtein()
                else {
                    return
                }
                if protein.bonds == nil {
                    // Update Status View
                    let bondCreationProgress = Progress()
                    let connectivityStatusAction = StatusAction(
                        type: .geometryGeneration,
                        description: NSLocalizedString("Generating geometry", comment: ""),
                        progress: bondCreationProgress
                    )
                    proteinViewModel.statusViewModel?.showStatusForAction(connectivityStatusAction)
                    // Compute links
                    await ConnectivityGenerator().computeConnectivity(
                        protein: protein,
                        dataSource: dataSource,
                        progress: bondCreationProgress
                    )
                    // Finished computing links, update status
                    proteinViewModel.statusViewModel?.signalActionFinished(connectivityStatusAction, withError: nil)
                }
            }
            await self.populateVisualizationBuffers(visualization: visualization, proteinViewModel: proteinViewModel)
            // Update internal visualization mode as seen by renderer
            await proteinViewModel.renderer.mutableState.setVisualization(visualization)
        }
    }
    
    // MARK: - Populate buffers
    
    func populateVisualizationBuffers(
        visualization: ProteinVisualizationOption,
        proteinViewModel: ProteinViewModel,
        isInitialAnimation: Bool = false
    ) async {
        
        guard let dataSource = await proteinViewModel.dataSource,
              let visualizationViewModel = await proteinViewModel.visualizationViewModel,
              let colorBy = await proteinViewModel.colorViewModel?.colorBy
        else {
            return
        }
        
        await proteinViewModel.renderer.mutableState.populateVisualizationBuffers(
            visualization: visualization,
            dataSource: dataSource,
            visualizationViewModel: visualizationViewModel,
            colorBy: colorBy,
            isInitialAnimation: isInitialAnimation
        )
    }
}
