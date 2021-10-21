//
//  CreateImpostorSpheres.metal
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 21/10/21.
//

#include <metal_stdlib>
#include "AtomProperties.h"
#include "GeneratedVertex.h"

using namespace metal;

kernel void createImpostorSpheres(const device simd_float3 *atomPoints [[ buffer(0) ]],
                                  const device uint8_t *atomType [[ buffer(1) ]],
                                  device GeneratedVertex *generatedVertices [[ buffer(2) ]],
                                  device uint32_t *generatedIndices [[ buffer(3) ]],
                                  uint i [[ thread_position_in_grid ]],
                                  uint l [[ thread_position_in_threadgroup ]]) {
    // TO-DO
}
