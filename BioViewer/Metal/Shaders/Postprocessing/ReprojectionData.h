//
//  ReprojectionData.h
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 16/4/23.
//

#ifndef ReprojectionData_h
#define ReprojectionData_h

#include <simd/simd.h>
#include "../../SharedDataStructs.h"

typedef struct {
    
    /// Reprojects from the current frame's NDC to the previous frame's NDC.
    simd_float4x4 reprojection_matrix;
    /// Width of the render target.
    int32_t renderWidth;
    /// Height of the render target.
    int32_t renderHeight;
    /// Pixel jitter in NDC coordinates (-0.5 to 0.5).
    simd_float2 pixel_jitter;
    /// Jitter performed on the projection, in texture coordinates.
    simd_float2 texel_jitter;
    /// Jitter performed on the projection, in texture coordinates.
    simd_float2 previous_texel_jitter;
    
} ReprojectionData;

#endif /* ReprojectionData_h */
