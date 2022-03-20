//
//  ComputeSDFGrid.metal
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 18/3/22.
//

#include <metal_stdlib>
#include "SDFGrid.h"
#include "../SharedDataStructs.h"

using namespace metal;

float Smoothed_Signed_Distance(float combined_signed_distance, float van_der_waals_distance_atom) {
    return min(combined_signed_distance, van_der_waals_distance_atom);
}

int getCellID(float x, float y, float z, float cellRadius, int cellsPerDimension, int currentCellNumber){
    
    int maxCellNumber = cellsPerDimension*cellsPerDimension*cellsPerDimension;
    
    int cellID = 0;
    cellID += cellsPerDimension*cellsPerDimension * int(cellsPerDimension * ((z+cellRadius)/(2*cellRadius)));
    cellID += cellsPerDimension * int(cellsPerDimension * ((y+cellRadius)/(2*cellRadius)));
    cellID += int(cellsPerDimension * ((x+cellRadius)/(2*cellRadius)));
    
    cellID += maxCellNumber*currentCellNumber;
    
    return cellID;
}

simd_float3 get_cell_center(int cell_index, float grid_size, int grid_resolution) {
    
    float cell_size = grid_size / grid_resolution;
    int cells_per_plane = grid_resolution * grid_resolution;
    int cells_per_row = grid_resolution;
        
    int number_of_full_planes = cell_index / cells_per_plane;
    int number_of_cells_in_full_planes = number_of_full_planes * cells_per_plane;
    
    int number_of_full_rows_in_last_plane = (cell_index - number_of_cells_in_full_planes) / cells_per_row;
    int number_of_cells_in_full_rows = number_of_full_rows_in_last_plane * cells_per_row;
    
    int number_of_cells_in_last_row = cell_index - number_of_cells_in_full_planes - number_of_cells_in_full_rows;

    float z = number_of_full_planes * cell_size + (cell_size / 2) - (grid_size / 2);
    float y = number_of_full_rows_in_last_plane * cell_size + (cell_size / 2) - (grid_size / 2);
    float x = number_of_cells_in_last_row * cell_size + (cell_size / 2) - (grid_size / 2);
    
    return simd_float3(x, y, z);
}

kernel void compute_SDF_Grid(device simd_float3 *atom_positions [[ buffer(0) ]],
                             device uint8_t *atom_types [[ buffer(1) ]],
                             device float *grid_values [[ buffer(2) ]],
                             constant SDFGrid &sdf_grid [[ buffer(3) ]],
                             constant AtomRadii &atom_radii [[buffer(4)]],
                             uint cell_index [[ thread_position_in_grid ]],
                             uint l [[ thread_position_in_threadgroup ]]) {
    
    // Position of the grid point in world space
    simd_float3 grid_point_position = get_cell_center(cell_index,
                                                      sdf_grid.grid_size,
                                                      sdf_grid.grid_resolution);
    
    // Typical signed distance is usually not 'combined' per nature: it's only
    // the signed distance to the closest point of the implicit surface. However,
    // since we're going to artificially 'smooth' the surface to approximate the
    // Solvent Excluded Surface, each atom will have a (small, depending on
    // distance to the grid point) contribution to the resulting computed signed
    // distance, therefore being 'combined'.
    //
    // The contribution to the final outputted value of the signed distance of
    // VdW surfaces that are not the closest to the grid point vanishes if the
    // Smoothed_Signed_Distance just returns the min of the pair of values, making
    // the created mesh converge to the non-smoothed surface (the Van Der Waals
    // surface, instead of the SES).
    float combined_signed_distance = INFINITY;
    
    // Loop over every atom (each one generates a VdW surface)
    for (int index_atom = 0; index_atom < sdf_grid.number_of_atoms; index_atom++) {
        
        /*- Distance to Van Der Waals surface of the atom -*/
        
        // Radius of the atom that generates the VdW surface
        float atom_radius = atom_radii.atomRadius[ atom_types[index_atom] ];
        // Atom position of the center of the VdW surface in world space
        simd_float3 atom_position = atom_positions[index_atom];
        // Distance from closest point of the VdW surface of the atom to the
        float van_der_waals_distance_atom = distance(grid_point_position, atom_position) - atom_radius;
        
        /*- Update the combined signed distance value -*/
        
        combined_signed_distance = Smoothed_Signed_Distance(combined_signed_distance, van_der_waals_distance_atom);
    }
    
    grid_values[cell_index] = combined_signed_distance;
 }
