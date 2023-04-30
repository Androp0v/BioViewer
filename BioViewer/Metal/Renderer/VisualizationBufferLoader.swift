//
//  VisualizationScene.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 31/12/21.
//

import Foundation
import SwiftUI

class VisualizationBufferLoader {
    
    // MARK: - Handle visualization
    
    var currentTask: Task<Void, Never>?
    weak var proteinViewModel: ProteinViewModel?
    
    func handleVisualizationChange(
        visualization: ProteinVisualizationOption,
        proteinViewModel: ProteinViewModel
    ) {
        
        // Save reference to proteinViewModel
        self.proteinViewModel = proteinViewModel
        
        // Cancel previously running visualization handling task (if any)
        currentTask?.cancel()
        
        // Add a new geometry creation task
        currentTask = Task {
            await self.populateVisualizationBuffers(visualization: visualization, proteinViewModel: proteinViewModel)
            // Update internal visualization mode as seen by renderer
            await proteinViewModel.renderer.mutableState.scene.currentVisualization = visualization
        }
    }
    
    // MARK: - Populate buffers
    
    private func populateVisualizationBuffers(visualization: ProteinVisualizationOption, proteinViewModel: ProteinViewModel) async {
        
        guard let protein = await proteinViewModel.dataSource?.getFirstProtein(),
              let animator = await proteinViewModel.renderer.mutableState.scene.animator,
              let visualizationViewModel = proteinViewModel.visualizationViewModel else { return }

        switch visualization {
        
        // MARK: - Solid spheres
        case .solidSpheres:
            
            // Change pipeline
            proteinViewModel.renderer.remakeImpostorPipelineForVariant(variant: .solidSpheres)
            
            // Animate radii changes
            animator.bufferLoader = self
            if await visualizationViewModel.solidSpheresRadiusOption == .vanDerWaals {
                await animator.animateRadiiChange(
                    finalRadii: AtomRadiiGenerator.vanDerWaalsRadii(scale: visualizationViewModel.solidSpheresVDWScale),
                    duration: 0.15
                )
            } else {
                await animator.animateRadiiChange(
                    finalRadii: AtomRadiiGenerator.fixedRadii(radius: visualizationViewModel.solidSpheresFixedAtomRadii),
                    duration: 0.15
                )
            }
            
        // MARK: - Ball and stick
        case .ballAndStick:

            // Compute model connectivity if not already present
            if protein.bonds == nil {
                // Update Status View
                await proteinViewModel.statusViewModel?.statusUpdate(statusText: NSLocalizedString("Generating geometry", comment: ""))
                
                // Compute links
                await ConnectivityGenerator().computeConnectivity(protein: protein, proteinViewModel: proteinViewModel)
                
                // Finished computing links, update status
                await proteinViewModel.statusViewModel?.statusFinished(action: .geometryGeneration)
            }
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
                    finalRadii: AtomRadiiGenerator.fixedRadii(radius: visualizationViewModel.ballAndSticksFixedAtomRadii),
                    duration: 0.15
                )
            } else {
                await animator.animateRadiiChange(
                    finalRadii: AtomRadiiGenerator.vanDerWaalsRadii(scale: visualizationViewModel.ballAndSticksVDWScale),
                    duration: 0.15
                )
            }
        }
    }
    
    // MARK: - Impostor sphere buffer
    
    func populateImpostorSphereBuffers(atomRadii: AtomRadii) async {
        
        guard let proteinViewModel = proteinViewModel,
              let colorViewModel = proteinViewModel.colorViewModel,
              let proteinFile = await proteinViewModel.dataSource?.getFirstFile(),
              let proteins = await proteinViewModel.dataSource?.modelsForFile(file: proteinFile) else {
            return
        }
        let configuration = await VisualizationConfiguration(
            atomRadii: atomRadii,
            colorBy: colorViewModel.colorBy,
            atomColors: colorViewModel.elementColors
        )
        await proteinViewModel.renderer.mutableState.populateImpostorSphereBuffers(
            proteins: proteins,
            configuration: configuration
        )
    }
}
