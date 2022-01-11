//
//  FrameData.h
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 17/10/21.
//

#ifndef FrameData_h
#define FrameData_h

#include <simd/simd.h>
#include "../SharedDataStructs.h"

/// Maximum number of colours that can be passed down to the GPU using FrameData.
#define MAX_ATOM_COLORS 64

typedef struct {
    
    /// Number of atoms in a single configuration.
    int atoms_per_configuration;
    
    /// Model to view matrix
    simd_float4x4 model_view_matrix;
    
    /// Inverse of model to view matrix
    simd_float4x4 inverse_model_view_matrix;

    /// Projection matrix
    simd_float4x4 projectionMatrix;

    /// Rotation matrix
    simd_float4x4 rotation_matrix;
    
    /// Inverse rotation matrix
    simd_float4x4 inverse_rotation_matrix;
    
    /// Shadow projection matrix
    simd_float4x4 shadowProjectionMatrix;
    
    /// Rotation matrix to view the model from the sun's point of view.
    simd_float4x4 sun_rotation_matrix;
    
    /// Inverse rotation matrix to view the model from the sun's point of view.
    simd_float4x4 inverse_sun_rotation_matrix;
    
    /// Transform from camera coordinates to sun's perspective coordinates.
    simd_float4x4 camera_to_shadow_projection_matrix;
    
    /// Color by subunit, used as a boolean.
    int8_t colorBySubunit;
    
    /// Whether it should cast shadows.
    int8_t has_shadows;
    /// The strength of the shadow color subtraction, from 0 to 1.
    float shadow_strength;
    
    /// Whether it should cast shadows.
    int8_t has_depth_cueing;
    /// The strength of the depth cueing, from 0 to 1.
    float depth_cueing_strength;
    
    /// Displayed atomic color in hard-spheres visualization mode.
    /// When spheres are coloured by element, only the first 6 elements of the array will be used.
    /// When spheres are coloured by subunit, all the array may be used.
    simd_float4 atomColor [MAX_ATOM_COLORS];
    
    /// Atom radii for each atom type.
    AtomRadii atom_radii;

} FrameData;

#endif /* FrameData_h */
