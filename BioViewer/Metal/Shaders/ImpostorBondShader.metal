//
//  ImpostorBondShader.metal
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 29/12/21.
//

#include <metal_stdlib>
#include "FrameData.h"
#include "../Meshes/GeneratedVertex.h"
#include "../Meshes/AtomProperties.h"

#define PERCENTAGE_CLOSE_FILTERING

using namespace metal;

struct ImpostorBondVertexOut{
    float4 position [[position]];
    float3 atomCenter;
    half2 billboardMapping;
};

// MARK: - Constants
constant bool hq_sample_count [[ function_constant(0) ]];

// MARK: - Functions

half2 VogelDiskSampleFIXME(half radius_scale, int sampleIndex, int samplesCount, float phi) {
    half GoldenAngle = 2.4f;

    half r = radius_scale * sqrt(sampleIndex + 0.5f) / sqrt(half(samplesCount));
    half theta = sampleIndex * GoldenAngle + phi;

    half2 sine_cosine;
    sincos(theta, sine_cosine);
  
    return half2(r * sine_cosine.y, r * sine_cosine.x);
}


// MARK: - Vertex function

vertex ImpostorBondVertexOut impostor_bond_vertex(const device BillboardVertex *vertex_buffer [[ buffer(0) ]],
                                                  const device FrameData& frameData [[ buffer(1) ]],
                                                  unsigned int vid [[ vertex_id ]]) {

    // Initialize the returned VertexOut structure
    ImpostorBondVertexOut normalized_impostor_vertex;
    
    // Set attributes
    normalized_impostor_vertex.billboardMapping = half2(vertex_buffer[vid].billboardMapping.xy);

    // Fetch the matrices
    simd_float4x4 model_view_matrix = frameData.model_view_matrix;
    simd_float4x4 projectionMatrix = frameData.projectionMatrix;
    simd_float4x4 rotation_matrix = frameData.rotation_matrix;
    simd_float4x4 inverse_rotation_matrix = frameData.inverse_rotation_matrix;
    
    // Rotate the model in world space
    float4 rotated_atom_centers = rotation_matrix * float4(vertex_buffer[vid].billboard_world_center.x,
                                                           vertex_buffer[vid].billboard_world_center.y,
                                                           vertex_buffer[vid].billboard_world_center.z,
                                                           1.0);
    
    // To rotate the billboards so they are facing the screen, first rotate them like the model,
    // along the protein axis.
    float4 rotated_model = rotation_matrix * float4(vertex_buffer[vid].position.x,
                                                    vertex_buffer[vid].position.y,
                                                    vertex_buffer[vid].position.z,
                                                    1.0);
    /*
    // Then translate the triangle to the origin of coordinates
    rotated_model.xyz = rotated_model.xyz - rotated_atom_centers.xyz;
    // Reverse the rotation by rotating in the opposite rotation along the billboard axis, NOT
    // the protein axis.
    rotated_model = inverse_rotation_matrix * rotated_model;
    // Translate the triangles back to their positions, now that they're already rotated
    rotated_model.xyz = rotated_model.xyz + rotated_atom_centers.xyz;
    */
    
    // Transform the world space coordinates to eye space coordinates
    float4 eye_position = model_view_matrix * rotated_model;
    
    // Transform the atom positions from world space to eye space
    normalized_impostor_vertex.atomCenter = (model_view_matrix * rotated_atom_centers).xyz;
    
    // Transform the eye space coordinates to normalized device coordinates
    normalized_impostor_vertex.position = projectionMatrix * eye_position;
    
    // Return the processed vertex
    return normalized_impostor_vertex;
    
}

// MARK: - Fragment function

struct ImpostorBondFragmentOut{
    half4 color [[ color(0) ]];
};

// [[stage_in]] uses the output from the basic_vertex vertex function
fragment ImpostorBondFragmentOut impostor_bond_fragment(ImpostorBondVertexOut impostor_vertex [[stage_in]],
                                                        const device FrameData& frameData [[ buffer(1) ]],
                                                        depth2d<float> shadowMap [[ texture(0) ]],
                                                        sampler shadowSampler [[ sampler(0) ]]) {
    
    // Declare output
    ImpostorBondFragmentOut output;
    
    // Phong diffuse shading
    half3 sunRayDirection = half3(0.7071067812, 0.7071067812, 0);
    half reflectivity = 0.3;
    
    // Add base color
    half3 shadedColor = half3(frameData.bond_color.r, frameData.bond_color.g, frameData.bond_color.b);
    
    /*
    // dot = x^2 + y^2
    half length = sqrt(1.0 - dot(impostor_vertex.billboardMapping, impostor_vertex.billboardMapping));
    
    // Discard pixels outside the sphere center (no need to do the sqrt)
    if (length > 1) {
        discard_fragment();
    }
    
    // Compute the normal in atom space
    half3 normal = half3(impostor_vertex.billboardMapping.x,
                         impostor_vertex.billboardMapping.y,
                         -length);
    
    // Compute the position of the fragment in camera space
    // FIXME: Replace 0.5 with bond_radius
    float3 spherePosition = (float3(normal) * 0.5) + impostor_vertex.atomCenter;
    
    // Compute Phong diffuse component
    half phongDiffuse = dot(normal, sunRayDirection) * reflectivity;
    shadedColor = saturate(shadedColor + phongDiffuse);
    
    // Recompute fragment depth
    simd_float4x4 projectionMatrix = frameData.projectionMatrix;
    float4 sphereClipPosition = ( projectionMatrix * float4(spherePosition.x,
                                                            spherePosition.y,
                                                            spherePosition.z,
                                                            1.0) );
    float normalizedDeviceCoordinatesDepth = sphereClipPosition.z / sphereClipPosition.w;
    output.depth = normalizedDeviceCoordinatesDepth;
    
    // Depth cueing
    if (frameData.has_depth_cueing) {
        shadedColor.rgb -= frameData.depth_cueing_strength * half3(normalizedDeviceCoordinatesDepth,
                                                                   normalizedDeviceCoordinatesDepth,
                                                                   normalizedDeviceCoordinatesDepth);
    }
    
    // Add hard shadows
    if (frameData.has_shadows) {
        
        simd_float4x4 camera_to_shadow_projection_matrix = frameData.camera_to_shadow_projection_matrix;
        float3 sphereShadowClipPosition = ( camera_to_shadow_projection_matrix * float4(spherePosition.x,
                                                                                        spherePosition.y,
                                                                                        spherePosition.z,
                                                                                        1.0)).xyz;
        
        // When calculating texture coordinates to sample from shadow map, flip the y/t coordinate and
        // convert from the [-1, 1] range of clip coordinates to [0, 1] range of
        // used for texture sampling
        sphereShadowClipPosition.y *= -1;
        sphereShadowClipPosition.xy += 1.0;
        sphereShadowClipPosition.xy /= 2;
        
        #ifndef PERCENTAGE_CLOSE_FILTERING
        float shadow_sample = shadowMap.sample_compare(shadowSampler,
                                                       sphereShadowClipPosition.xy,
                                                       sphereShadowClipPosition.z);
            
        bool is_sunlit = false;
        if (shadow_sample > 0) {
            is_sunlit = true;
        }
        
        // Add the shadow to the shadedColor by subtracting color
        shadedColor.rgb -= frameData.shadow_strength * (1 - is_sunlit);
        #else
        float sunlit_fraction = 0;
        int sample_count;
        if (hq_sample_count) {
            sample_count = 128;
        } else {
            sample_count = 2;
        }
        for (int sample_index = 0; sample_index < sample_count; sample_index++) {
            // FIXME: 0.001 should be proportional to the typical atom size
            // TO-DO: VogelDiskSample may be called with a random number instead of 0 for the rotation
            half2 sample_offset = VogelDiskSampleFIXME(0.001, sample_index, sample_count, 0);
            sunlit_fraction += shadowMap.sample_compare(shadowSampler,
                                                        sphereShadowClipPosition.xy + float2(sample_offset),
                                                        sphereShadowClipPosition.z);
        }
        
        // Add the shadow to the shadedColor by subtracting color
        shadedColor.rgb -= frameData.shadow_strength * (1 - sunlit_fraction / sample_count);
        #endif
    }
    */
    
    // Final color
    output.color = half4(shadedColor.rgb, 1.0);
    
    return output;
}

