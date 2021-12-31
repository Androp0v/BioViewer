//
//  VisualizationScene.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 31/12/21.
//

import Foundation

extension ProteinRenderer {
    
    // FIXME: Handle on non-main thread
    func handleVisualizationChange(visualization: ProteinVisualizationOption) {
        
        guard let protein = proteinDataSource?.files.first?.protein else { return }

        switch visualization {
            
        // MARK: - None
        case .none:
            removeBuffers()
            
        // MARK: - Solid spheres
        case .solidSpheres:
            // Generate a billboard quad for each atom in the protein
            let (vertexData, subunitData, atomTypeData, indexData) = MetalScheduler.shared.createImpostorSpheres(protein: protein)
            guard var vertexData = vertexData else { return }
            guard var subunitData = subunitData else { return }
            guard var atomTypeData = atomTypeData else { return }
            guard var indexData = indexData else { return }
            
            // Pass the new mesh to the renderer
            addBillboardingBuffers(vertexBuffer: &vertexData,
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
            
            // Pass the new mesh to the renderer
            addBillboardingBuffers(vertexBuffer: &vertexData,
                                   subunitBuffer: &subunitData,
                                   atomTypeBuffer: &atomTypeData,
                                   indexBuffer: &indexData)
            
            // Add link buffers to the structure
            let (linkVertexBuffer, linkIndexBuffer) = MetalScheduler.shared.createLinksGeometry(protein: protein)
            guard var linkVertexBuffer = linkVertexBuffer else { return }
            guard var linkIndexBuffer = linkIndexBuffer else { return }
            addBillboardingLinks(vertexBuffer: &linkVertexBuffer,
                                 indexBuffer: &linkIndexBuffer)
        }
    }
}
