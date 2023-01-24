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
            
            DispatchQueue.main.sync {
                // Update internal visualization mode as seen by renderer
                proteinViewModel.renderer.scene.currentVisualization = visualization
            }
        }
    }
    
    // MARK: - Populate buffers
    
    private func populateVisualizationBuffers(visualization: ProteinVisualizationOption, proteinViewModel: ProteinViewModel) async {
        
        guard let protein = proteinViewModel.dataSource?.getFirstProtein(),
              let animator = proteinViewModel.renderer.scene.animator,
              let visualizationViewModel = proteinViewModel.visualizationViewModel else { return }

        switch visualization {
        
        // MARK: - Solid spheres
        case .solidSpheres:
            
            // Change pipeline
            proteinViewModel.renderer.remakeImpostorPipelineForVariant(variant: .solidSpheres)
            
            // Animate radii changes
            animator.bufferLoader = self
            if visualizationViewModel.solidSpheresRadiusOption == .vanDerWaals {
                animator.animateRadiiChange(
                    finalRadii: AtomRadiiGenerator.vanDerWaalsRadii(scale: visualizationViewModel.solidSpheresVDWScale),
                    duration: 0.15
                )
            } else {
                animator.animateRadiiChange(
                    finalRadii: AtomRadiiGenerator.fixedRadii(radius: visualizationViewModel.solidSpheresFixedAtomRadii),
                    duration: 0.15
                )
            }
            
        // MARK: - Ball and stick
        case .ballAndStick:

            // Compute model connectivity if not already present
            if protein.bonds == nil {
                // Update Status View
                proteinViewModel.statusViewModel?.statusUpdate(statusText: NSLocalizedString("Generating geometry", comment: ""))
                
                // Compute links
                await ConnectivityGenerator().computeConnectivity(protein: protein, proteinViewModel: proteinViewModel)
                
                // Finished computing links, update status
                proteinViewModel.statusViewModel?.statusFinished(action: .geometryGeneration)
            }
            guard let bondData = protein.bonds else { return }
            guard !Task.isCancelled else { return }
            
            // Update configuration selector with bonds
            guard let bondsPerConfiguration = protein.bondsPerConfiguration else { return }
            guard let bondsConfigurationArrayStart = protein.bondsConfigurationArrayStart else { return }
            proteinViewModel.renderer.scene.configurationSelector?.addBonds(
                bondsPerConfiguration: bondsPerConfiguration,
                bondArrayStarts: bondsConfigurationArrayStart
            )
            
            // Avoid trying to create a buffer with 0 length if no bonds are found (causes a crash)
            if !bondData.isEmpty {
                // Add bond buffers to the structure
                let (bondVertexBuffer, bondIndexBuffer) = MetalScheduler.shared.createBondsGeometry(bondData: bondData)
                guard var bondVertexBuffer = bondVertexBuffer else { return }
                guard var bondIndexBuffer = bondIndexBuffer else { return }
                
                // Pass bond buffers to the renderer
                proteinViewModel.renderer.setBillboardingBonds(
                    vertexBuffer: &bondVertexBuffer,
                    indexBuffer: &bondIndexBuffer
                )
            }
            
            // Change pipeline
            proteinViewModel.renderer.remakeImpostorPipelineForVariant(variant: .ballAndSticks)
            
            // Animate radii changes
            animator.bufferLoader = self
            if visualizationViewModel.ballAndStickRadiusOption == .fixed {
                animator.animateRadiiChange(
                    finalRadii: AtomRadiiGenerator.fixedRadii(radius: visualizationViewModel.ballAndSticksFixedAtomRadii),
                    duration: 0.15
                )
            } else {
                animator.animateRadiiChange(
                    finalRadii: AtomRadiiGenerator.vanDerWaalsRadii(scale: visualizationViewModel.ballAndSticksVDWScale),
                    duration: 0.15
                )
            }
        }
    }
    
    // MARK: - Impostor sphere buffer
    
    func populateImpostorSphereBuffers(atomRadii: AtomRadii) {
        
        guard let proteinViewModel = proteinViewModel,
              let colorViewModel = proteinViewModel.colorViewModel,
              let proteinFile = proteinViewModel.dataSource?.getFirstFile(),
              let proteins = proteinViewModel.dataSource?.modelsForFile(file: proteinFile) else {
            return
        }
        
        // Generate a billboard quad for each atom in the protein
        let (vertexData, subunitData, atomTypeData, atomResidueData, indexData) = MetalScheduler.shared.createImpostorSpheres(
            proteins: proteins,
            atomRadii: atomRadii
        )
        guard let vertexData = vertexData else { return }
        guard let subunitData = subunitData else { return }
        guard let atomTypeData = atomTypeData else { return }
        guard let indexData = indexData else { return }
        
        // Create ConfigurationSelector for new data
        guard let configurationSelector = createConfigurationSelector(proteins: proteins) else { return }
        
        // Pass the new mesh to the renderer
        proteinViewModel.renderer.setBillboardingBuffers(
            billboardVertexBuffers: vertexData,
            subunitBuffer: subunitData,
            atomTypeBuffer: atomTypeData,
            atomResidueBuffer: atomResidueData,
            indexBuffer: indexData,
            configurationSelector: configurationSelector
        )
        
        // Create color buffer if needed
        if !((proteinViewModel.renderer.atomColorBuffer?.length ?? 0)
                / MemoryLayout<SIMD4<Int16>>.stride == proteins.reduce(0) { $0 + $1.atomCount }) {
            proteinViewModel.renderer.createAtomColorBuffer(
                proteins: proteins,
                subunitBuffer: subunitData,
                atomTypeBuffer: atomTypeData,
                colorList: colorViewModel.elementColors,
                colorBy: colorViewModel.colorBy
            )
        }
    }
    
    // MARK: - ConfigurationSelector
    
    func createConfigurationSelector(proteins: [Protein]) -> ConfigurationSelector? {
        guard let proteinViewModel = proteinViewModel else { return nil }
        
        if let currentSelector = proteinViewModel.renderer.scene.configurationSelector,
           currentSelector.proteins == proteins {
            return currentSelector
        }

        var totalAtomCount: Int = 0
        var subunitIndices = [Int]()
        var subunitLengths = [Int]()
        for protein in proteins {
            totalAtomCount += protein.atomCount
            if let subunits = protein.subunits {
                for subunit in subunits {
                    subunitIndices.append(subunit.startIndex)
                    subunitLengths.append(subunit.atomCount)
                }
            }
        }
        return ConfigurationSelector(
            for: proteins,
            in: proteinViewModel.renderer.scene,
            atomsPerConfiguration: totalAtomCount,
            subunitIndices: subunitIndices,
            subunitLengths: subunitLengths,
            configurationCount: proteins.first?.configurationCount ?? 1 // FIXME: Remove ?? 1
        )
    }
}
