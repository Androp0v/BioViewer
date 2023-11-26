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
              let protein = await dataSource.getFirstProtein(),
              let animator = await proteinViewModel.renderer.mutableState.scene.animator,
              let visualizationViewModel = await proteinViewModel.visualizationViewModel
        else { return }

        switch visualization {
        
        // MARK: - Solid spheres
        case .solidSpheres:
            
            // Change pipeline
            proteinViewModel.renderer.remakeImpostorPipelineForVariant(variant: .solidSpheres)
            
            // Animate radii changes
            if isInitialAnimation {
                await proteinViewModel.renderer.mutableState.setAtomRadii(.zero)
            }
            animator.bufferLoader = self
            if await visualizationViewModel.solidSpheresRadiusOption == .vanDerWaals {
                await animator.animateRadiiChange(
                    finalRadii: .scaledVanDerWaals(scale: visualizationViewModel.solidSpheresVDWScale),
                    duration: 0.35
                )
            } else {
                await animator.animateRadiiChange(
                    finalRadii: .fixed(radius: visualizationViewModel.solidSpheresFixedAtomRadii),
                    duration: 0.35
                )
            }
            
        // MARK: - Ball and stick
        case .ballAndStick:

            guard let bondData = protein.bonds else { return }
            guard !Task.isCancelled else { return }
            
            // Update configuration selector with bonds
            guard let bondsPerConfiguration = protein.bondsPerConfiguration else { return }
            guard let bondsConfigurationArrayStart = protein.bondsConfigurationArrayStart else { return }
            
            await proteinViewModel.renderer.mutableState.updateBonds(
                bondData: bondData,
                bondsPerConfiguration: bondsPerConfiguration,
                bondsConfigurationArrayStart: bondsConfigurationArrayStart
            )
            
            // Change pipeline
            proteinViewModel.renderer.remakeImpostorPipelineForVariant(variant: .ballAndSticks)
            
            // Animate radii changes
            animator.bufferLoader = self
            if await visualizationViewModel.ballAndStickRadiusOption == .fixed {
                await animator.animateRadiiChange(
                    finalRadii: .fixed(radius: visualizationViewModel.ballAndSticksFixedAtomRadii),
                    duration: 0.35
                )
            } else {
                await animator.animateRadiiChange(
                    finalRadii: .scaledVanDerWaals(scale: visualizationViewModel.ballAndSticksVDWScale),
                    duration: 0.35
                )
            }
        }
    }
    
    // MARK: - Impostor sphere buffer
    
    func populateImpostorSphereBuffers(atomRadii: AtomRadii) async {
        
        guard let proteinViewModel = proteinViewModel,
              let colorViewModel = await proteinViewModel.colorViewModel,
              let proteinFile = await proteinViewModel.dataSource?.getFirstFile(),
              let proteins = await proteinViewModel.dataSource?.modelsForFile(file: proteinFile) else {
            return
        }
        let configuration = await VisualizationConfiguration(
            atomRadii: atomRadii,
            colorBy: colorViewModel.colorBy
        )
        await proteinViewModel.renderer.mutableState.populateImpostorSphereBuffers(
            proteins: proteins,
            configuration: configuration
        )
    }
}
