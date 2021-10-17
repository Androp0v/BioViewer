//
//  FrameData.h
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 17/10/21.
//

#ifndef FrameData_h
#define FrameData_h

#include <simd/simd.h>

typedef struct {

    /// Model to view matrix
    simd_float4x4 model_view_matrix;

    /// Projection matrix
    simd_float4x4 projectionMatrix;

    /// Rotation matrix
    simd_float4x4 rotation_matrix;

    /// Displayed atomic radii in hard-spheres visualization mode
    float atomRadius [6];

    /// Displayed atomic color in hard-spheres visualization mode
    simd_float4 atomColor [6];

} FrameData;

#endif /* FrameData_h */
