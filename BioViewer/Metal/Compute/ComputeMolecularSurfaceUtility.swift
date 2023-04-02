//
//  ComputeMolecularSurfaceUtility.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/5/22.
//

import Foundation
import Metal
import simd

class ComputeMolecularSurfaceUtility {
    
    let protein: Protein
    
    /// Size of the box that encloses the entire protein.
    var boxSize: Float = 0.0
    // FIXME: Remove, grid resolution will be SIMD group based
    /// Resolution of the grid that encloses the entire protein.
    let gridResolution: Int
    /// Size of the cell neighbour checker, in Armstrongs.
    let neighbourCellSize: Float = 5.0
    /// Resolution of the neighbour grid (number of neighbour cells per dimension).
    var neighbourGridResolution: Int = 0
    
    /// Number of threads that a single SIMD group can handle. Obtained using the `threadExecutionWidth`
    /// property of the compute pipeline state.
    var threadsPerNBGrid: Int?
    
    init(protein: Protein, gridResolution: Int = 200) {
        self.protein = protein
        self.gridResolution = gridResolution
        
        (self.boxSize, self.neighbourGridResolution) = optimalBox(boundingSphereRadius: protein.boundingSphere.radius)
    }
    
    func createMolecularSurface() -> MTLBuffer? {
        let neighbours = createNeighbourGrid()
        /*guard let sdfBuffer = createSDFGrid() else {
            return nil
        }
        return debugCreatePointsFromSDFGrid(sdfBuffer: sdfBuffer)*/
        return nil
    }
    
    // MARK: - Private
    
    private func optimalBox(boundingSphereRadius: Float) -> (Float, Int) {
        let numberOfCells = Int(ceil(2 * boundingSphereRadius / neighbourCellSize))
        let optimalSize = Float(numberOfCells) * neighbourCellSize
        
        BioViewerLogger.shared.log(type: .info,
                                   category: .computeSurfaceUtility,
                                   message: """
                                            NeighbourGrid has \(numberOfCells * numberOfCells * numberOfCells)
                                            (\(numberOfCells)x\(numberOfCells)x\(numberOfCells)) cells.
                                            """)
        return (optimalSize, numberOfCells)
    }
        
    private func createNeighbourGrid() -> [Int: [simd_float3]] {
        var neighbourDict = [Int: [simd_float3]]()
        for atomPosition in protein.atoms {
            let nbCellID = getNBCellID(position: atomPosition)
            if var atomsInCellList = neighbourDict[nbCellID] {
                atomsInCellList.append(atomPosition)
                neighbourDict[nbCellID] = atomsInCellList
            } else {
                neighbourDict[nbCellID] = [atomPosition]
            }
        }
        
        return neighbourDict
    }
    
    private func createSDFGrid() -> MTLBuffer? {
        
        let sdfBuffer = MetalScheduler.shared.computeSDFGrid(protein: protein,
                                                             boxSize: boxSize,
                                                             gridResolution: gridResolution)
        return sdfBuffer
    }
    
    // MARK: - Utilities
    
    private func getNBCellID(position: simd_float3) -> Int {

        var cellID: Int = 0
        
        cellID += neighbourGridResolution
                    * neighbourGridResolution
                    * Int(Float(neighbourGridResolution) * ((position.z + boxSize/2) / boxSize))
        
        cellID += neighbourGridResolution
                    * Int(Float(neighbourGridResolution) * ((position.y + boxSize/2) / boxSize))
        
        cellID += Int(Float(neighbourGridResolution) * ((position.x + boxSize/2) / boxSize))
        
        return cellID
    }
    
    private func optimalThreadsPerNBGroup() {
        
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
