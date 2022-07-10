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
    
    func handleVisualizationChange(visualization: ProteinVisualizationOption, proteinViewModel: ProteinViewModel) {
        
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
        
        guard let protein = proteinViewModel.dataSource.getFirstProtein() else {
            return
        }
        guard let animator = proteinViewModel.renderer.scene.animator else { return }

        switch visualization {
        
        // MARK: - Solid spheres
        case .solidSpheres:
            
            // Change pipeline
            proteinViewModel.renderer.remakeImpostorPipelineForVariant(variant: .solidSpheres)
            
            // Animate radii changes
            animator.bufferLoader = self
            if proteinViewModel.solidSpheresRadiusOption == .vanDerWaals {
                animator.animateRadiiChange(finalRadii: AtomRadiiGenerator.vanDerWaalsRadii(scale: proteinViewModel.solidSpheresVDWScale),
                                            duration: 0.15)
            } else {
                animator.animateRadiiChange(finalRadii: AtomRadiiGenerator.fixedRadii(radius: proteinViewModel.solidSpheresFixedAtomRadii),
                                            duration: 0.15)
            }
            
        // MARK: - Ball and stick
        case .ballAndStick:

            // Compute model connectivity if not already present
            if protein.bonds == nil {
                // Update Status View
                proteinViewModel.statusUpdate(statusText: NSLocalizedString("Generating geometry", comment: ""))
                
                // Compute links
                await ConnectivityGenerator().computeConnectivity(protein: protein, proteinViewModel: proteinViewModel)
                
                // Finished computing links, update status
                proteinViewModel.statusFinished(action: .geometryGeneration)
            }
            guard let bondData = protein.bonds else { return }
            guard !Task.isCancelled else { return }
            
            // Update configuration selector with bonds
            guard let bondsPerConfiguration = protein.bondsPerConfiguration else { return }
            guard let bondsConfigurationArrayStart = protein.bondsConfigurationArrayStart else { return }
            proteinViewModel.renderer.scene.configurationSelector?.addBonds(bondsPerConfiguration: bondsPerConfiguration,
                                                                            bondArrayStarts: bondsConfigurationArrayStart)
            
            // Add bond buffers to the structure
            let (bondVertexBuffer, bondIndexBuffer) = MetalScheduler.shared.createBondsGeometry(bondData: bondData)
            guard var bondVertexBuffer = bondVertexBuffer else { return }
            guard var bondIndexBuffer = bondIndexBuffer else { return }
            
            // Pass bond buffers to the renderer
            proteinViewModel.renderer.setBillboardingBonds(vertexBuffer: &bondVertexBuffer,
                                                           indexBuffer: &bondIndexBuffer)
            
            // Change pipeline
            proteinViewModel.renderer.remakeImpostorPipelineForVariant(variant: .ballAndSticks)
            
            // Animate radii changes
            animator.bufferLoader = self
            if proteinViewModel.ballAndStickRadiusOption == .fixed {
                animator.animateRadiiChange(finalRadii: AtomRadiiGenerator.fixedRadii(radius: proteinViewModel.ballAndSticksFixedAtomRadii),
                                            duration: 0.15)
            } else {
                animator.animateRadiiChange(finalRadii: AtomRadiiGenerator.vanDerWaalsRadii(scale: proteinViewModel.ballAndSticksVDWScale),
                                            duration: 0.15)
            }
        }
    }
    
    // MARK: - Impostor sphere buffer
    
    func populateImpostorSphereBuffers(atomRadii: AtomRadii) {
        
        guard let proteinViewModel = proteinViewModel else {
            return
        }
        guard let proteinFile = proteinViewModel.dataSource.getFirstFile() else {
            return
        }
        guard let proteins = proteinViewModel.dataSource.modelsForFile(file: proteinFile) else {
            return
        }
        
        // Generate a billboard quad for each atom in the protein
        let (vertexData, subunitData, atomTypeData, indexData) = MetalScheduler.shared.createImpostorSpheres(proteins: proteins,
                                                                                                             atomRadii: atomRadii)
        guard let vertexData = vertexData else { return }
        guard let subunitData = subunitData else { return }
        guard let atomTypeData = atomTypeData else { return }
        guard let indexData = indexData else { return }
        
        // Pass the new mesh to the renderer
        proteinViewModel.renderer.setBillboardingBuffers(billboardVertexBuffers: vertexData,
                                                         subunitBuffer: subunitData,
                                                         atomTypeBuffer: atomTypeData,
                                                         indexBuffer: indexData)
        
        // Create color buffer if needed
        if !((proteinViewModel.renderer.atomColorBuffer?.length ?? 0) / MemoryLayout<SIMD4<Int16>>.stride == proteins.combinedAtomCount) {
            proteinViewModel.renderer.createAtomColorBuffer(proteins: proteins,
                                                            subunitBuffer: subunitData,
                                                            atomTypeBuffer: atomTypeData,
                                                            colorList: proteinViewModel.elementColors,
                                                            colorBy: proteinViewModel.colorBy)
        }
    }
}
