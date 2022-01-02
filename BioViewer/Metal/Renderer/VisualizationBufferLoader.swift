//
//  VisualizationScene.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 31/12/21.
//

import Foundation

class VisualizationBufferLoader {
    
    // MARK: - Handle visualization
    
    var currentTask: Task<Void, Never>?
    
    func handleVisualizationChange(visualization: ProteinVisualizationOption, proteinViewModel: ProteinViewModel) {
        
        // Cancel previously running visualization handling task (if any)
        currentTask?.cancel()
        
        // Update Status View
        proteinViewModel.statusUpdate(statusText: NSLocalizedString("Generating geometry", comment: ""))
        
        // Add a new geometry creation task
        currentTask = Task {
            await self.populateVisualizationBuffers(visualization: visualization, proteinViewModel: proteinViewModel)
            
            DispatchQueue.main.sync {
                // Update internal visualization mode as seen by renderer
                proteinViewModel.renderer.scene.currentVisualization = visualization
                
                // Update Status View
                proteinViewModel.statusFinished(action: .geometryGeneration)
            }
        }
    }
    
    // MARK: - Populate buffers
    
    private func populateVisualizationBuffers(visualization: ProteinVisualizationOption, proteinViewModel: ProteinViewModel) async {
        
        guard let protein = proteinViewModel.dataSource.files.first?.protein else { return }

        switch visualization {
            
        // MARK: - None
        case .none:
            proteinViewModel.renderer.removeBuffers()
            
        // MARK: - Solid spheres
        case .solidSpheres:
            // Generate a billboard quad for each atom in the protein
            let (vertexData, subunitData, atomTypeData, indexData) = MetalScheduler.shared.createImpostorSpheres(protein: protein)
            guard var vertexData = vertexData else { return }
            guard var subunitData = subunitData else { return }
            guard var atomTypeData = atomTypeData else { return }
            guard var indexData = indexData else { return }
            
            // Pass the new mesh to the renderer
            proteinViewModel.renderer.addBillboardingBuffers(vertexBuffer: &vertexData,
                                                             subunitBuffer: &subunitData,
                                                             atomTypeBuffer: &atomTypeData,
                                                             indexBuffer: &indexData)
            
            // Change pipeline
            proteinViewModel.renderer.remakeImpostorPipelineForVariant(variant: .solidSpheres)
            proteinViewModel.renderer.remakeShadowPipelineForVariant(useFixedRadius: false)
            
        // MARK: - Ball and stick
        case .ballAndStick:
            // Generate a billboard quad for each atom in the protein
            let (vertexData, subunitData, atomTypeData, indexData) = MetalScheduler.shared.createImpostorSpheres(protein: protein,
                                                                                                                 fixedRadius: true)
            guard var vertexData = vertexData else { return }
            guard var subunitData = subunitData else { return }
            guard var atomTypeData = atomTypeData else { return }
            guard var indexData = indexData else { return }
            
            // Compute model connectivity
            let linkData = await ConnectivityGenerator().computeConnectivity(protein: protein, proteinViewModel: proteinViewModel)
            if Task.isCancelled { return }
            
            // Add link buffers to the structure
            let (linkVertexBuffer, linkIndexBuffer) = MetalScheduler.shared.createLinksGeometry(linkData: linkData)
            guard var linkVertexBuffer = linkVertexBuffer else { return }
            guard var linkIndexBuffer = linkIndexBuffer else { return }
            
            // Pass atom buffers to the renderer
            proteinViewModel.renderer.addBillboardingBuffers(vertexBuffer: &vertexData,
                                                             subunitBuffer: &subunitData,
                                                             atomTypeBuffer: &atomTypeData,
                                                             indexBuffer: &indexData)
            // Pass link buffers to the renderer
            proteinViewModel.renderer.addBillboardingLinks(vertexBuffer: &linkVertexBuffer,
                                                           indexBuffer: &linkIndexBuffer)
            
            // Change pipeline
            proteinViewModel.renderer.remakeImpostorPipelineForVariant(variant: .ballAndSticks)
            proteinViewModel.renderer.remakeShadowPipelineForVariant(useFixedRadius: true)
        }
    }
}
