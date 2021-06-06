//
//  CreateAtomMesh.metal
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 5/6/21.
//

#include <metal_stdlib>
#include "AtomProperties.h"
using namespace metal;

kernel void createSphereModel(const device simd_float3 *atomPoints [[buffer(0)]],
                              const device uint8_t *atomType [[buffer(1)]],
                              device simd_float3 *generatedVertices [[buffer(2)]],
                              device uint32_t *generatedIndices [[buffer(3)]],
                              uint i [[thread_position_in_grid]],
                              uint l [[thread_position_in_threadgroup]]) {

    // Retrieve the radius and position of the atom
    const simd_float3 position = atomPoints[i];
    const uint32_t index = i * 12;
    const uint32_t index_2 = i * 60;
    const float radius = 1.5; // FIXME: atomType[atomType[i]];

    // Assign unitary icosahedron points (generated in scripts/UnitaryIcosahedron.py)
    generatedVertices[index] = simd_float3(-0.5257311121191336, 0.85065080835204, 0.0) * radius + position;
    generatedVertices[index+1] = simd_float3(0.5257311121191336, 0.85065080835204, 0.0) * radius + position;
    generatedVertices[index+2] = simd_float3(-0.5257311121191336, -0.85065080835204, 0.0) * radius + position;
    generatedVertices[index+3] = simd_float3(0.5257311121191336, -0.85065080835204, 0.0) * radius + position;
    generatedVertices[index+4] = simd_float3(0.0, -0.5257311121191336, 0.85065080835204) * radius + position;
    generatedVertices[index+5] = simd_float3(0.0, 0.5257311121191336, 0.85065080835204) * radius + position;
    generatedVertices[index+6] = simd_float3(0.0, -0.5257311121191336, -0.85065080835204) * radius + position;
    generatedVertices[index+7] = simd_float3(0.0, 0.5257311121191336, -0.85065080835204) * radius + position;
    generatedVertices[index+8] = simd_float3(0.85065080835204, 0.0, -0.5257311121191336) * radius + position;
    generatedVertices[index+9] = simd_float3(0.85065080835204, 0.0, 0.5257311121191336) * radius + position;
    generatedVertices[index+10] = simd_float3(-0.85065080835204, 0.0, -0.5257311121191336) * radius + position;
    generatedVertices[index+11] = simd_float3(-0.85065080835204, 0.0, 0.5257311121191336) * radius + position;

    // Assign index array (how the triangles are constructed)
    generatedIndices[index_2] = 0 + index;
    generatedIndices[index_2+1] = 11 + index;
    generatedIndices[index_2+2] = 5 + index;
    generatedIndices[index_2+3] = 0 + index;
    generatedIndices[index_2+4] = 5 + index;
    generatedIndices[index_2+5] = 1 + index;
    generatedIndices[index_2+6] = 0 + index;
    generatedIndices[index_2+7] = 1 + index;
    generatedIndices[index_2+8] = 7 + index;
    generatedIndices[index_2+9] = 0 + index;
    generatedIndices[index_2+10] = 7 + index;
    generatedIndices[index_2+11] = 10 + index;
    generatedIndices[index_2+12] = 0 + index;
    generatedIndices[index_2+13] = 10 + index;
    generatedIndices[index_2+14] = 11 + index;
    generatedIndices[index_2+15] = 1 + index;
    generatedIndices[index_2+16] = 5 + index;
    generatedIndices[index_2+17] = 9 + index;
    generatedIndices[index_2+18] = 5 + index;
    generatedIndices[index_2+19] = 11 + index;
    generatedIndices[index_2+20] = 4 + index;
    generatedIndices[index_2+21] = 11 + index;
    generatedIndices[index_2+22] = 10 + index;
    generatedIndices[index_2+23] = 2 + index;
    generatedIndices[index_2+24] = 10 + index;
    generatedIndices[index_2+25] = 7 + index;
    generatedIndices[index_2+26] = 6 + index;
    generatedIndices[index_2+27] = 7 + index;
    generatedIndices[index_2+28] = 1 + index;
    generatedIndices[index_2+29] = 8 + index;
    generatedIndices[index_2+30] = 3 + index;
    generatedIndices[index_2+31] = 9 + index;
    generatedIndices[index_2+32] = 4 + index;
    generatedIndices[index_2+33] = 3 + index;
    generatedIndices[index_2+34] = 4 + index;
    generatedIndices[index_2+35] = 2 + index;
    generatedIndices[index_2+36] = 3 + index;
    generatedIndices[index_2+37] = 2 + index;
    generatedIndices[index_2+38] = 6 + index;
    generatedIndices[index_2+39] = 3 + index;
    generatedIndices[index_2+40] = 6 + index;
    generatedIndices[index_2+41] = 8 + index;
    generatedIndices[index_2+42] = 3 + index;
    generatedIndices[index_2+43] = 8 + index;
    generatedIndices[index_2+44] = 9 + index;
    generatedIndices[index_2+45] = 4 + index;
    generatedIndices[index_2+46] = 9 + index;
    generatedIndices[index_2+47] = 5 + index;
    generatedIndices[index_2+48] = 2 + index;
    generatedIndices[index_2+49] = 4 + index;
    generatedIndices[index_2+50] = 11 + index;
    generatedIndices[index_2+51] = 6 + index;
    generatedIndices[index_2+52] = 2 + index;
    generatedIndices[index_2+53] = 10 + index;
    generatedIndices[index_2+54] = 8 + index;
    generatedIndices[index_2+55] = 6 + index;
    generatedIndices[index_2+56] = 7 + index;
    generatedIndices[index_2+57] = 9 + index;
    generatedIndices[index_2+58] = 8 + index;
    generatedIndices[index_2+59] = 1 + index;
}
