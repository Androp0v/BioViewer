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
    
} ReprojectionData;

#endif /* ReprojectionData_h */
