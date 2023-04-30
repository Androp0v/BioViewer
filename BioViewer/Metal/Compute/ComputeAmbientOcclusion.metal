//
//  ComputeAmbientOcclusion.metal
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 29/4/23.
//

#include <metal_stdlib>
#include "../SharedDataStructs.h"

using namespace metal;

kernel void compute_occlusion_texture(device simd_float3 *atom_positions [[ buffer(0) ]],
                                      device uint16_t *atom_types [[ buffer(1) ]],
                                      constant AtomRadii &atom_radii [[buffer(2)]],
                                      const texture3d<float, access::read_write>  ambient_occlusion [[ texture(0) ]],
                                      uint cell_index [[ thread_position_in_grid ]]) {
}
