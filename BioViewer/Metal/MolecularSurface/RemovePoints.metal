//
//  RemovePoints.metal
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 26/5/21.
//

#include <metal_stdlib>
using namespace metal;

constant float probeRadius [[ function_constant(0) ]];

/// Create a bitmask of the generated sphere points. Disable (false) points inside  solid, enabled if not inside other spheres (the true surface points).
kernel void removeSASPointsInsideSolid(const device simd_float3 *atomPoints [[buffer(0)]],
                                       const device float *atomRadii [[buffer(1)]],
                                       device simd_float3 *generatedSpherePoints [[buffer(2)]],
                                       /*constant int &atomCount [[buffer(3)]],*/
                                       device bool *bitmaskSAS [[buffer(3)]],
                                       uint i [[thread_position_in_grid]],
                                       uint l [[thread_position_in_threadgroup]]) {

    simd_float3 currentPoint = generatedSpherePoints[i];
    bool isInsideSolid = false;
    const int atomCount = 59574;
    const float tolerance = 0.01;

    // TO-DO: Make this faster by using a k-d tree or spatial subdivisions
    // Loop for all sphere points except the current sphere point
    for(int j=0; j < atomCount; j++){
        if (distance(currentPoint, atomPoints[j]) < (probeRadius + atomRadii[j] - tolerance)) {
            isInsideSolid = true;
            break;
        }
    }

    bitmaskSAS[i] = !isInsideSolid;
}
