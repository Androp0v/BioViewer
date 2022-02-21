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
        
        guard let protein = proteinViewModel.dataSource.files.first?.protein else { return }
        guard let animator = proteinViewModel.renderer.scene.animator else { return }

        switch visualization {
        
        // MARK: - Solid spheres
        case .solidSpheres:
            
            // Change pipeline
            proteinViewModel.renderer.remakeImpostorPipelineForVariant(variant: .solidSpheres)
            proteinViewModel.renderer.remakeShadowPipelineForVariant(useFixedRadius: false)
            
            // Animate radii changes
            animator.bufferLoader = self
            animator.animateRadiiChange(finalRadii: AtomRadiiGenerator.vanDerWaalsRadii(),
                                        duration: 0.15)
            
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
            proteinViewModel.renderer.remakeShadowPipelineForVariant(useFixedRadius: true)
            
            // Animate radii changes
            animator.bufferLoader = self
            animator.animateRadiiChange(finalRadii: AtomRadiiGenerator.fixedRadii(),
                                        duration: 0.15)
        }
    }
    
    // MARK: - Impostor sphere buffer
    
    func populateImpostorSphereBuffers(atomRadii: AtomRadii) {
        
        guard let protein = proteinViewModel?.dataSource.files.first?.protein else { return }
        
        // Generate a billboard quad for each atom in the protein
        let (vertexData, subunitData, atomTypeData, indexData) = MetalScheduler.shared.createImpostorSpheres(protein: protein,
                                                                                                             atomRadii: atomRadii)
        guard var vertexData = vertexData else { return }
        guard var subunitData = subunitData else { return }
        guard var atomTypeData = atomTypeData else { return }
        guard var indexData = indexData else { return }
        
        // Create and populate color buffer
        let colorData = createAtomColorArray(protein: protein,
                                             subunitBuffer: subunitData,
                                             atomTypeBuffer: atomTypeData,
                                             colorList: self.proteinViewModel?.elementColors,
                                             colorBy: self.proteinViewModel?.colorBy)
        guard var colorData = colorData else { return }
        
        // Pass the new mesh to the renderer
        proteinViewModel?.renderer.setBillboardingBuffers(vertexBuffer: &vertexData,
                                                          subunitBuffer: &subunitData,
                                                          atomTypeBuffer: &atomTypeData,
                                                          indexBuffer: &indexData)
        // Pass the color buffer to the renderer
        proteinViewModel?.renderer.setColorBuffer(colorBuffer: &colorData)
    }
    
    // MARK: - Color buffer
    
    private func createAtomColorArray(protein: Protein, subunitBuffer: MTLBuffer, atomTypeBuffer: MTLBuffer, colorList: [Color]?, colorBy: Int?) -> MTLBuffer? {
        
        // Retrieve device
        guard let device = MTLCreateSystemDefaultDevice() else { return nil }
        
        // Get the number of configurations
        let configurationCount = protein.configurationCount
        
        // WORKAROUND: The memory layout should conform to simd_half3's stride, which is
        // syntactic sugar for SIMD3<Float16>, but Float16 is (still) unavailable on macOS
        // due to lack of support on x86. We assume SIMD3<Int16> is packed in the same way
        // Metal packs the half3 type.
        guard let generatedColorBuffer = device.makeBuffer(
            length: protein.atomCount * configurationCount * MemoryLayout<SIMD3<Int16>>.stride
        ) else { return nil }
        
        return generatedColorBuffer
    }
}
