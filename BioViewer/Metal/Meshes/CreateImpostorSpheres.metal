//
//  CreateImpostorSpheres.metal
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 21/10/21.
//

#include <metal_stdlib>
#include "AtomProperties.h"
#include "GeneratedVertex.h"
#include "../SharedDataStructs.h"

using namespace metal;

// MARK: - Kernels

kernel void createImpostorSpheres(const device simd_float3 *atomPoints [[ buffer(0) ]],
                                  const device uint16_t *atomType [[ buffer(1) ]],
                                  device simd_half2 *generatedPositions [[ buffer(2) ]],
                                  device simd_float3 *generatedAtomCenters [[ buffer(3) ]],
                                  device simd_half2 *generatedBillboardMapping [[ buffer(4) ]],
                                  device half *generatedAtomRadius [[ buffer(5) ]],
                                  device uint32_t *generatedIndices [[ buffer(6) ]],
                                  constant uint32_t & totalAtomCount [[ buffer(7) ]],
                                  constant AtomRadii &atom_radii [[buffer(8)]],
                                  uint i [[ thread_position_in_grid ]],
                                  uint l [[ thread_position_in_threadgroup ]]) {
    // TO-DO
    
    // Retrieve the radius and position of the atom
    const simd_float3 position = atomPoints[i];
    const uint32_t index = i * 4;
    const uint32_t index_2 = i * 6;
    
    float radius = atom_radii.atomRadius[atomType[i % totalAtomCount]];
    
    // MARK: - Vertices

    generatedPositions[index+0] = simd_half2(radius, radius);
    generatedPositions[index+1] = simd_half2(-radius, radius);
    generatedPositions[index+2] = simd_half2(-radius, -radius);
    generatedPositions[index+3] = simd_half2(radius, -radius);
    
    generatedBillboardMapping[index+0] = simd_half2(1, 1);
    generatedBillboardMapping[index+1] = simd_half2(-1, 1);
    generatedBillboardMapping[index+2] = simd_half2(-1, -1);
    generatedBillboardMapping[index+3] = simd_half2(1, -1);
    
    generatedAtomCenters[index+0] = position;
    generatedAtomCenters[index+1] = position;
    generatedAtomCenters[index+2] = position;
    generatedAtomCenters[index+3] = position;
    
    generatedAtomRadius[index+0] = half(radius);
    generatedAtomRadius[index+1] = half(radius);
    generatedAtomRadius[index+2] = half(radius);
    generatedAtomRadius[index+3] = half(radius);
    
    // MARK: - Indices

    generatedIndices[index_2+0] = 0 + index;
    generatedIndices[index_2+1] = 2 + index;
    generatedIndices[index_2+2] = 1 + index;
    
    generatedIndices[index_2+3] = 2 + index;
    generatedIndices[index_2+4] = 0 + index;
    generatedIndices[index_2+5] = 3 + index;
}
