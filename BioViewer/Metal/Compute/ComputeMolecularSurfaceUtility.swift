//
//  ComputeMolecularSurfaceUtility.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/5/22.
//

import Foundation
import Metal

class ComputeMolecularSurfaceUtility {
    
    let protein: Protein
    
    /// Size of the cell neighbour checker, in Armstrongs.
    let neighbourCellSize: Float = 3.0
    
    var boxSize: Float = 0.0
    let gridResolution: Int
    
    init(protein: Protein, gridResolution: Int = 200) {
        self.protein = protein
        self.gridResolution = gridResolution
        
        self.boxSize = optimalBoxSize(boundingSphereRadius: protein.boundingSphere.radius)
    }
    
    func createMolecularSurface() -> MTLBuffer? {
        
        guard let sdfBuffer = createSDFGrid() else {
            return nil
        }
        return debugCreatePointsFromSDFGrid(sdfBuffer: sdfBuffer)
    }
    
    // MARK: - Private
    
    private func optimalBoxSize(boundingSphereRadius: Float) -> Float {
        let numberOfCells = ceil(2 * boundingSphereRadius / neighbourCellSize)
        let optimalSize = numberOfCells * neighbourCellSize
        BioViewerLogger.shared.log(type: .info,
                                   category: .ComputeSurfaceUtility,
                                   message: "NeighbourGrid has \(numberOfCells) cells.")
        return optimalSize
    }
        
    private func createNeighbourGrid() {
        
    }
    
    private func createSDFGrid() -> MTLBuffer? {
        
        let sdfBuffer = MetalScheduler.shared.computeSDFGrid(protein: protein,
                                                             boxSize: boxSize,
                                                             gridResolution: gridResolution)
        return sdfBuffer
    }
    
    // MARK: - Debug
    
    func debugCreatePointsFromSDFGrid(sdfBuffer: MTLBuffer) -> MTLBuffer? {
        
        func getCellCenterFrom(cellID: Int) -> simd_float3 {
            let cell_size = boxSize / Float(gridResolution)
            let cells_per_plane = gridResolution * gridResolution
            let cells_per_row = gridResolution
                
            let number_of_full_planes = cellID / cells_per_plane
            let number_of_cells_in_full_planes = number_of_full_planes * cells_per_plane
            
            let number_of_full_rows_in_last_plane = (cellID - number_of_cells_in_full_planes) / cells_per_row
            let number_of_cells_in_full_rows = number_of_full_rows_in_last_plane * cells_per_row
            
            let number_of_cells_in_last_row = cellID - number_of_cells_in_full_planes - number_of_cells_in_full_rows

            let z = Float(number_of_full_planes) * cell_size + (cell_size / 2) - (boxSize / 2)
            let y = Float(number_of_full_rows_in_last_plane) * cell_size + (cell_size / 2) - (boxSize / 2)
            let x = Float(number_of_cells_in_last_row) * cell_size + (cell_size / 2) - (boxSize / 2)
            
            return simd_float3(x, y, z)
        }
        
        var pointsInsideVolume = [DebugPoint]()
        
        let generatedSDFBufferToSwift = sdfBuffer.contents().assumingMemoryBound(to: Float.self)
        for cellID in 0..<(gridResolution * gridResolution * gridResolution) {
            if generatedSDFBufferToSwift[cellID] < 0 {
                // Point is inside volume
                let cellCenter = getCellCenterFrom(cellID: cellID)
                pointsInsideVolume.append(DebugPoint(position: cellCenter))
            }
        }
        
        return MetalScheduler.shared.makeBufferFromArray(array: pointsInsideVolume)
    }
}
