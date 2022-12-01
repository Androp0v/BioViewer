//
//  CreateExpandableBillboardSpheres.metal
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 30/11/22.
//

#include <metal_stdlib>
#include "AtomProperties.h"
#include "GeneratedVertex.h"
#include "../SharedDataStructs.h"

using namespace metal;

// MARK: - Kernels

kernel void createExpandableBillboardSpheres(const device simd_float3 *atomPoints [[ buffer(0) ]],
                                             const device uint16_t *atomType [[ buffer(1) ]],
                                             device simd_float3 *generatedAtomCenters [[ buffer(3) ]],
                                             device half *generatedAtomRadius [[ buffer(5) ]],
                                             constant uint32_t & totalAtomCount [[ buffer(7) ]],
                                             constant AtomRadii &atom_radii [[buffer(8)]],
                                             uint i [[ thread_position_in_grid ]],
                                             uint l [[ thread_position_in_threadgroup ]]) {
    
    // Retrieve the radius and position of the atom
    const simd_float3 position = atomPoints[i];
    float radius = atom_radii.atomRadius[atomType[i % totalAtomCount]];
    
    // MARK: - Atom centers
    
    generatedAtomCenters[i] = position;
    
    // MARK: - Radius
    
    generatedAtomRadius[i] = half(radius);
}
