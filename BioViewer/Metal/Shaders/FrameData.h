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

typedef struct {
    
    /// Number of atoms in a single configuration.
    int atoms_per_configuration;
    
    /// The depth bias, in Normalized Device Coordinates, that is applied in the
    /// depth and shadow depth pre-passes, to avoid artifacts due to the regular
    /// and shadow passes excluding fragments whose depth is close to the
    /// pre-computed depth of the pre-pass. Should be the equivalent of about
    /// 2 Armstrongs (translated to NDCs).
    float depth_bias;
    
    // MARK: - Matrices
    
    /// Model to view matrix
    simd_float4x4 model_view_matrix;

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
    
    /// Transform from camera coordinates to sun's perspective coordinates.
    simd_float4x4 camera_to_shadow_projection_matrix;
    
    // MARK: - Bonds
    
    simd_float3 bond_color;
        
    // MARK: - Shadows
    
    /// Whether it should cast shadows.
    int8_t has_shadows;
    /// The strength of the shadow color subtraction, from 0 to 1.
    float shadow_strength;
    
    /// Whether it should use depth cueing.
    int8_t has_depth_cueing;
    /// The strength of the depth cueing, from 0 to 1.
    float depth_cueing_strength;

} FrameData;

#endif /* FrameData_h */
