//
//  MoleculeSurface.metal
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 22/5/21.
//

#include <metal_stdlib>
using namespace metal;


/// Create Solvent Accessible Surface (SAS) points
kernel void createSASPoints(const device simd_float3 *atomPoints [[buffer(0)]],
                            const device float *atomRadii [[buffer(1)]],
                            constant float &probeRadius [[buffer(2)]],
                            device simd_float3 *generatedSpherePoints [[buffer(3)]],
                            uint i [[thread_position_in_grid]],
                            uint l [[thread_position_in_threadgroup]]) {

    // Retrieve the radius and position of the atom
    const simd_float3 position = atomPoints[i];
    const float radius = atomRadii[i];

    // Assign unitary icosahedron points (generated in scripts/UnitaryIcosahedron.py)
    generatedSpherePoints[i+0] = simd_float3(-0.5257311121191336, 0.85065080835204, 0.0) * (radius + probeRadius) + position;
    generatedSpherePoints[i+1] = simd_float3(0.5257311121191336, 0.85065080835204, 0.0) * (radius + probeRadius) + position;
    generatedSpherePoints[i+2] = simd_float3(-0.5257311121191336, -0.85065080835204, 0.0) * (radius + probeRadius) + position;
    generatedSpherePoints[i+3] = simd_float3(0.5257311121191336, 0.85065080835204, 0.0) * (radius + probeRadius) + position;
    generatedSpherePoints[i+4] = simd_float3(0.0, -0.5257311121191336, 0.85065080835204) * (radius + probeRadius) + position;
    generatedSpherePoints[i+5] = simd_float3(0.0, 0.5257311121191336, 0.85065080835204) * (radius + probeRadius) + position;
    generatedSpherePoints[i+6] = simd_float3(0.0, -0.5257311121191336, -0.85065080835204) * (radius + probeRadius) + position;
    generatedSpherePoints[i+7] = simd_float3(0.0, 0.5257311121191336, -0.85065080835204) * (radius + probeRadius) + position;
    generatedSpherePoints[i+8] = simd_float3(0.85065080835204, 0.0, -0.5257311121191336) * (radius + probeRadius) + position;
    generatedSpherePoints[i+9] = simd_float3(0.85065080835204, 0.0, 0.5257311121191336) * (radius + probeRadius) + position;
    generatedSpherePoints[i+10] = simd_float3(-0.85065080835204, 0.0, -0.5257311121191336) * (radius + probeRadius) + position;
    generatedSpherePoints[i+11] = simd_float3(-0.85065080835204, 0.0, 0.5257311121191336) * (radius + probeRadius) + position;

}
