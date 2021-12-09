//
//  ImpostorSphereShader.metal
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 29/10/21.
//

#include <metal_stdlib>
#include "FrameData.h"
#include "../Meshes/GeneratedVertex.h"
#include "../Meshes/AtomProperties.h"

#define DEPTH_CUEING true

using namespace metal;

struct ImpostorVertexOut{
    float4 position [[position]];
    float3 atomCenter;
    float2 billboardMapping;
    uint8_t atomType;
    float4 color;
};

// MARK: - Vertex function

vertex ImpostorVertexOut impostor_vertex(const device BillboardVertex *vertex_buffer [[ buffer(0) ]],
                                         const device int16_t *subunitIndex [[ buffer(1) ]],
                                         const device uint8_t *atomType [[ buffer(2) ]],
                                         const device FrameData& frameData [[ buffer(3) ]],
                                         unsigned int vid [[ vertex_id ]]) {

    // Initialize the returned VertexOut structure
    ImpostorVertexOut normalized_impostor_vertex;
    int verticesPerAtom = 4;
    
    // Set attributes
    normalized_impostor_vertex.billboardMapping = vertex_buffer[vid].billboardMapping;
    normalized_impostor_vertex.atomType = atomType[vid / verticesPerAtom];

    // Fetch the matrices
    simd_float4x4 model_view_matrix = frameData.model_view_matrix;
    simd_float4x4 projectionMatrix = frameData.projectionMatrix;
    simd_float4x4 rotation_matrix = frameData.rotation_matrix;
    simd_float4x4 inverse_rotation_matrix = frameData.inverse_rotation_matrix;
    
    // Rotate the model in world space
    float4 rotated_atom_centers = rotation_matrix * float4(vertex_buffer[vid].atomCenter.x,
                                                           vertex_buffer[vid].atomCenter.y,
                                                           vertex_buffer[vid].atomCenter.z,
                                                           1.0);

    // To rotate the billboards so they are facing the screen, first rotate them like the model,
    // along the protein axis.
    float4 rotated_model = rotation_matrix * float4(vertex_buffer[vid].position.x,
                                                    vertex_buffer[vid].position.y,
                                                    vertex_buffer[vid].position.z,
                                                    1.0);
    // Then translate the triangle to the origin of coordinates
    rotated_model.xyz = rotated_model.xyz - rotated_atom_centers.xyz;
    // Reverse the rotation by rotating in the opposite rotation along the billboard axis, NOT
    // the protein axis.
    rotated_model = inverse_rotation_matrix * rotated_model;
    // Translate the triangles back to their positions, now that they're already rotated
    rotated_model.xyz = rotated_model.xyz + rotated_atom_centers.xyz;
    
    // Transform the world space coordinates to eye space coordinates
    float4 eye_position = model_view_matrix * rotated_model;
    
    // Transform the atom positions from world space to eye space
    normalized_impostor_vertex.atomCenter = (model_view_matrix * rotated_atom_centers).xyz;
    
    // Transform the eye space coordinates to normalized device coordinates
    normalized_impostor_vertex.position = projectionMatrix * eye_position;
    
    if (frameData.colorBySubunit) {
        // Color the atom based on the subunit type
        normalized_impostor_vertex.color = frameData.atomColor[ subunitIndex[vid / verticesPerAtom] ];
    } else {
        // Color the atom based on the atom type
        normalized_impostor_vertex.color = frameData.atomColor[ atomType[vid / verticesPerAtom] ];
    }

    // Return the processed vertex
    return normalized_impostor_vertex;
}

// MARK: - Fragment function

struct ImpostorFragmentOut{
    half4 color [[ color(0) ]];
    float depth [[ depth(any) ]];
};

// [[stage_in]] uses the output from the basic_vertex vertex function
fragment ImpostorFragmentOut impostor_fragment(ImpostorVertexOut impostor_vertex [[stage_in]],
                                               const device FrameData& frameData [[ buffer(1) ]],
                                               depth2d<float> shadowMap [[ texture(0) ]]) {
    
    // Declare output
    ImpostorFragmentOut output;
    
    // Phong diffuse shading
    half3 sunRayDirection = normalize(half3(1, 1, 0));
    half reflectivity = 0.3;
    
    // Add base color
    half3 shadedColor = half3(impostor_vertex.color.r,
                              impostor_vertex.color.g,
                              impostor_vertex.color.b);
    
    
    // squaredLength = x^2 + y^2
    half squaredLength = dot(impostor_vertex.billboardMapping, impostor_vertex.billboardMapping);
    
    // Discard pixels outside the sphere center (no need to do the sqrt)
    if (squaredLength > 1) {
        discard_fragment();
    }
    
    // Compute the normal in camera space
    float3 normal = float3(impostor_vertex.billboardMapping.x,
                           impostor_vertex.billboardMapping.y,
                           -sqrt(1.0 - squaredLength));
    
    // Compute the position of the fragment in camera space
    float3 spherePosition = (normal * atomRadius[impostor_vertex.atomType]) + impostor_vertex.atomCenter;
    
    // Add Phong diffuse component
    shadedColor = shadedColor + dot(normal, float3(sunRayDirection)) * reflectivity;
    
    // Recompute fragment depth
    simd_float4x4 projectionMatrix = frameData.projectionMatrix;
    float4 sphereClipPosition = ( projectionMatrix * float4(spherePosition.x,
                                                            spherePosition.y,
                                                            spherePosition.z,
                                                            1.0) );
    float normalizedDeviceCoordinatesDepth = sphereClipPosition.z / sphereClipPosition.w;
    output.depth = normalizedDeviceCoordinatesDepth;
    
    // Depth cueing
    if (DEPTH_CUEING) {
        shadedColor.rgb -= 0.3 * half3(normalizedDeviceCoordinatesDepth, normalizedDeviceCoordinatesDepth, normalizedDeviceCoordinatesDepth);
    }
    
    // Add hard shadows
    simd_float4x4 inverse_model_view_matrix = frameData.inverse_model_view_matrix;
    float4 sphereShadowModelPosition = ( inverse_model_view_matrix * float4(spherePosition.x,
                                                                            spherePosition.y,
                                                                            spherePosition.z,
                                                                            1.0) );
    simd_float4x4 sun_rotation_matrix = frameData.sunRotationMatrix;
    float4 sphereShadowWorldPosition = ( sun_rotation_matrix * float4(sphereShadowModelPosition.x,
                                                                      sphereShadowModelPosition.y,
                                                                      sphereShadowModelPosition.z,
                                                                      1.0) );
    simd_float4x4 shadow_projection_matrix = frameData.shadowProjectionMatrix;
    float4 sphereShadowClipPosition = ( shadow_projection_matrix * float4(sphereShadowWorldPosition.x,
                                                                          sphereShadowWorldPosition.y,
                                                                          sphereShadowWorldPosition.z,
                                                                          1.0));
    
    constexpr sampler shadowSampler(coord::normalized,
                                    filter::linear,
                                    mip_filter::none,
                                    address::clamp_to_border,
                                    border_color::opaque_white,
                                    compare_func::less_equal);
    
    // When calculating texture coordinates to sample from shadow map, flip the y/t coordinate and
    // convert from the [-1, 1] range of clip coordinates to [0, 1] range of
    // used for texture sampling
    sphereShadowClipPosition.y *= -1;
    sphereShadowClipPosition.xy += 1.0;
    sphereShadowClipPosition.xy /= 2;
    
    float shadow_sample = shadowMap.sample_compare(shadowSampler,
                                                   sphereShadowClipPosition.xy,
                                                   sphereShadowClipPosition.z);
    float is_sunlit = 0;
    if (shadow_sample > 0) {
        is_sunlit = 1;
    }
    // Color
    float testDepthInSunCoordinates = shadowMap.sample(shadowSampler, sphereShadowClipPosition.xy);
    output.color = half4(shadedColor.r - 0.3 * (1 - is_sunlit), // sphereShadowClipPosition.x, // shadedColor.r - 0.5 * shadow_sample,
                         shadedColor.g - 0.3 * (1 - is_sunlit), // sphereShadowClipPosition.y, // shadedColor.g - 0.5 * shadow_sample,
                         shadedColor.b - 0.3 * (1 - is_sunlit), // sphereShadowClipPosition.z, // testDepthInSunCoordinates, // shadedColor.b - 0.5 * shadow_sample,
                         1.0); // testDepthInSunCoordinates);
    
    /*output.color = half4(is_sunlit, // sphereShadowClipPosition.x, // shadedColor.r - 0.5 * shadow_sample,
                         is_sunlit, // sphereShadowClipPosition.y, // shadedColor.g - 0.5 * shadow_sample,
                         is_sunlit, // sphereShadowClipPosition.z, // testDepthInSunCoordinates, // shadedColor.b - 0.5 * shadow_sample,
                         1.0); // testDepthInSunCoordinates);*/
    
    return output;
}
