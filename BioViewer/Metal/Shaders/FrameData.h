//
//  FrameData.h
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 17/10/21.
//

#ifndef FrameData_h
#define FrameData_h

#include <simd/simd.h>

/// Maximum number of colours that can be passed down to the GPU using FrameData.
#define MAX_ATOM_COLORS 40

typedef struct {

    /// Model to view matrix
    simd_float4x4 model_view_matrix;

    /// Projection matrix
    simd_float4x4 projectionMatrix;

    /// Rotation matrix
    simd_float4x4 rotation_matrix;
    
    /// Inverse rotation matrix
    simd_float4x4 inverse_rotation_matrix;

    /// Displayed atomic radii in hard-spheres visualization mode
    float atomRadius [6];

    /// Displayed atomic color in hard-spheres visualization mode.
    /// When spheres are coloured by element, only the first 6 elements of the array will be used.
    /// When spheres are coloured by subunit, all the array may be used.
    simd_float4 atomColor [MAX_ATOM_COLORS];

} FrameData;

#endif /* FrameData_h */
