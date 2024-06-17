//
//  PopulateBuffers.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 26/11/23.
//

import BioViewerFoundation
import Foundation

extension ProteinRenderer {
    
    func animatedFileDeletion(colorBy: ProteinColorByOption, proteins: [Protein]) async {
        await sceneAnimator.animateRadiiChange(
            renderer: self,
            finalRadii: .zero,
            duration: 0.35,
            colorBy: colorBy,
            proteins: proteins
        )
        try? await Task.sleep(for: .seconds(0.5))
    }
    
    func populateVisualizationBuffers(
        visualization: ProteinVisualizationOption,
        dataSource: ProteinDataSource,
        visualizationViewModel: ProteinVisualizationViewModel,
        colorBy: ProteinColorByOption,
        isInitialAnimation: Bool = false
    ) async {
        
        // FIXME: Avoid this hacky way of retrieving current models
        guard let protein = await dataSource.getFirstProtein(),
              let proteinFile = await dataSource.getFirstFile(),
              let proteins = await dataSource.modelsForFile(file: proteinFile)
        else {
            return
        }

        switch visualization {
        
        // MARK: - Solid spheres
        case .solidSpheres:
            
            // Change pipeline
            remakeImpostorPipelineForVariant(variant: .solidSpheres)
            
            // Animate radii changes
            if isInitialAnimation {
                setAtomRadii(.zero)
            }
            if await visualizationViewModel.solidSpheresRadiusOption == .vanDerWaals {
                await sceneAnimator.animateRadiiChange(
                    renderer: self,
                    finalRadii: .scaledVanDerWaals(scale: visualizationViewModel.solidSpheresVDWScale),
                    duration: 0.35,
                    colorBy: colorBy,
                    proteins: proteins
                )
            } else {
                await sceneAnimator.animateRadiiChange(
                    renderer: self,
                    finalRadii: .fixed(radius: visualizationViewModel.solidSpheresFixedAtomRadii),
                    duration: 0.35,
                    colorBy: colorBy,
                    proteins: proteins
                )
            }
            
        // MARK: - Ball and stick
        case .ballAndStick:

            guard let bondData = protein.bonds else { return }
            guard !Task.isCancelled else { return }
            
            // Update configuration selector with bonds
            guard let bondsPerConfiguration = protein.bondsPerConfiguration else { return }
            guard let bondsConfigurationArrayStart = protein.bondsConfigurationArrayStart else { return }
            
            await updateBonds(
                bondData: bondData,
                bondsPerConfiguration: bondsPerConfiguration,
                bondsConfigurationArrayStart: bondsConfigurationArrayStart
            )
            
            // Change pipeline
            remakeImpostorPipelineForVariant(variant: .ballAndSticks)
            
            // Animate radii changes
            if await visualizationViewModel.ballAndStickRadiusOption == .fixed {
                await sceneAnimator.animateRadiiChange(
                    renderer: self,
                    finalRadii: .fixed(radius: visualizationViewModel.ballAndSticksFixedAtomRadii),
                    duration: 0.35,
                    colorBy: colorBy,
                    proteins: proteins
                )
            } else {
                await sceneAnimator.animateRadiiChange(
                    renderer: self,
                    finalRadii: .scaledVanDerWaals(scale: visualizationViewModel.ballAndSticksVDWScale),
                    duration: 0.35,
                    colorBy: colorBy,
                    proteins: proteins
                )
            }
        }
    }
    
    func sceneAnimatorCallback(atomRadii: AtomRadii, colorBy: ProteinColorByOption, proteins: [Protein]) async {
        let configuration = VisualizationConfiguration(
            atomRadii: atomRadii,
            colorBy: colorBy
        )
        await populateImpostorSphereBuffers(
            proteins: proteins,
            configuration: configuration
        )
    }
}
