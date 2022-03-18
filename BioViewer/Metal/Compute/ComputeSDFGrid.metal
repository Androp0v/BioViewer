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

kernel void compute_SDF_Grid(device simd_float3 *atom_positions [[ buffer(0) ]],
                             device uint8_t *atom_types [[ buffer(1) ]],
                             device float *grid_values [[ buffer(2) ]],
                             constant SDFGrid &sdf_grid [[ buffer(3) ]],
                             constant AtomRadii &atom_radii [[buffer(4)]],
                             uint i [[ thread_position_in_grid ]],
                             uint l [[ thread_position_in_threadgroup ]]) {
    // TO-DO
    for (int j = 0; i < sdf_grid.number_of_atoms; i++) {
        float radius = atom_radii.atomRadius[atom_types[j % sdf_grid.number_of_atoms]];
        // Do things
    }
 }
