//
//  MoleculeSurface.metal
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 22/5/21.
//

#include <metal_stdlib>
using namespace metal;

// MARK: - Function constants

// MTLFunctionConstants, set to constant at pipeline creation time,
// allow for compiler optimizations.
constant float radius [[ function_constant(0) ]];
constant float probeRadius [[ function_constant(1) ]];

// MARK: - Kernels

/// Create Solvent Accessible Surface (SAS) points
kernel void createSASPoints(const device simd_float3 *atomPoints [[buffer(0)]],
                            /*const device float *atomRadii [[buffer(1)]],*/
                            /*constant float &probeRadius [[buffer(2)]],*/
                            device simd_float3 *generatedSpherePoints [[buffer(1)]],
                            uint i [[thread_position_in_grid]],
                            uint l [[thread_position_in_threadgroup]]) {

    // Retrieve the radius and position of the atom
    const simd_float3 position = atomPoints[i];
    const int index = i * 12;

    // Assign unitary icosahedron points (generated in scripts/UnitaryIcosahedron.py)
    generatedSpherePoints[index] = simd_float3(-0.5257311121191336, 0.85065080835204, 0.0) * (radius + probeRadius) + position;
    generatedSpherePoints[index+1] = simd_float3(0.5257311121191336, 0.85065080835204, 0.0) * (radius + probeRadius) + position;
    generatedSpherePoints[index+2] = simd_float3(-0.5257311121191336, -0.85065080835204, 0.0) * (radius + probeRadius) + position;
    generatedSpherePoints[index+3] = simd_float3(0.5257311121191336, 0.85065080835204, 0.0) * (radius + probeRadius) + position;
    generatedSpherePoints[index+4] = simd_float3(0.0, -0.5257311121191336, 0.85065080835204) * (radius + probeRadius) + position;
    generatedSpherePoints[index+5] = simd_float3(0.0, 0.5257311121191336, 0.85065080835204) * (radius + probeRadius) + position;
    generatedSpherePoints[index+6] = simd_float3(0.0, -0.5257311121191336, -0.85065080835204) * (radius + probeRadius) + position;
    generatedSpherePoints[index+7] = simd_float3(0.0, 0.5257311121191336, -0.85065080835204) * (radius + probeRadius) + position;
    generatedSpherePoints[index+8] = simd_float3(0.85065080835204, 0.0, -0.5257311121191336) * (radius + probeRadius) + position;
    generatedSpherePoints[index+9] = simd_float3(0.85065080835204, 0.0, 0.5257311121191336) * (radius + probeRadius) + position;
    generatedSpherePoints[index+10] = simd_float3(-0.85065080835204, 0.0, -0.5257311121191336) * (radius + probeRadius) + position;
    generatedSpherePoints[index+11] = simd_float3(-0.85065080835204, 0.0, 0.5257311121191336) * (radius + probeRadius) + position;
}
