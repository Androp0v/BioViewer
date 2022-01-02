//
//  VisualizationScene.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 31/12/21.
//

import Foundation

class VisualizationBufferLoader {
    
    // MARK: - Handle visualization
    
    func handleVisualizationChange(visualization: ProteinVisualizationOption, proteinViewModel: ProteinViewModel) {
        DispatchQueue.init(label: "Geometry generation", qos: .userInitiated).async {
            self.populateVisualizationBuffers(visualization: visualization, proteinViewModel: proteinViewModel)
            
            DispatchQueue.main.sync {
                // Update internal visualization mode as seen by renderer
                proteinViewModel.renderer.scene.currentVisualization = visualization
            }
        }
    }
    
    // MARK: - Populate buffers
    
    private func populateVisualizationBuffers(visualization: ProteinVisualizationOption, proteinViewModel: ProteinViewModel) {
        
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
            
        // MARK: - Ball and stick
        case .ballAndStick:
            // Generate a billboard quad for each atom in the protein
            let (vertexData, subunitData, atomTypeData, indexData) = MetalScheduler.shared.createImpostorSpheres(protein: protein,
                                                                                                                 fixedRadius: true)
            guard var vertexData = vertexData else { return }
            guard var subunitData = subunitData else { return }
            guard var atomTypeData = atomTypeData else { return }
            guard var indexData = indexData else { return }
            
            // Add link buffers to the structure
            let (linkVertexBuffer, linkIndexBuffer) = MetalScheduler.shared.createLinksGeometry(protein: protein)
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
        }
    }
}
