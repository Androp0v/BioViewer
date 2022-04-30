//
//  ShadowShader.metal
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 8/12/21.
//

#include <metal_stdlib>
#include "FrameData.h"
#include "../Meshes/GeneratedVertex.h"
#include "../Meshes/AtomProperties.h"

// Depth offset used to avoid shadow acne
#define DEPTH_OFFSET 0.001

using namespace metal;

struct ShadowVertexOut{
    float4 position [[position]];
    float3 atomCenter;
    half2 billboardMapping;
    float atom_radius;
};

// MARK: - Vertex function

vertex ShadowVertexOut shadow_vertex(const device BillboardVertex *vertex_buffer [[ buffer(0) ]],
                                     const device uint8_t *atomType [[ buffer(1) ]],
                                     const device FrameData& frameData [[ buffer(2) ]],
                                     unsigned int vertex_id [[ vertex_id ]]) {

    // Initialize the returned VertexOut structure
    ShadowVertexOut normalized_impostor_vertex;
    
    // Set attributes
    normalized_impostor_vertex.billboardMapping = half2(vertex_buffer[vertex_id].billboardMapping.x, vertex_buffer[vertex_id].billboardMapping.y);
    normalized_impostor_vertex.atom_radius = vertex_buffer[vertex_id].atom_radius;

    // Fetch the matrices
    simd_float4x4 shadow_projection_matrix = frameData.shadowProjectionMatrix;
    simd_float4x4 sun_rotation_matrix = frameData.sun_rotation_matrix;
    simd_float4x4 inverse_sun_rotation_matrix = frameData.inverse_sun_rotation_matrix;
    
    // Rotate the model in world space
    float4 rotated_atom_centers = sun_rotation_matrix * float4(vertex_buffer[vertex_id].billboard_world_center.x,
                                                               vertex_buffer[vertex_id].billboard_world_center.y,
                                                               vertex_buffer[vertex_id].billboard_world_center.z,
                                                               1.0);

    // To rotate the billboards so they are facing the screen, first rotate them like the model,
    // along the protein axis.
    float4 rotated_model = sun_rotation_matrix * float4(vertex_buffer[vertex_id].position.x,
                                                                vertex_buffer[vertex_id].position.y,
                                                                vertex_buffer[vertex_id].position.z,
                                                                1.0);
    // Then translate the triangle to the origin of coordinates
    rotated_model.xyz = rotated_model.xyz - rotated_atom_centers.xyz;
    // Reverse the rotation by rotating in the opposite rotation along the billboard axis, NOT
    // the protein axis.
    rotated_model = inverse_sun_rotation_matrix * rotated_model;
    // Translate the triangles back to their positions, now that they're already rotated
    rotated_model.xyz = rotated_model.xyz + rotated_atom_centers.xyz;
        
    // For the ShadowShader, we use model coordinates instead of camera coordinates
    normalized_impostor_vertex.atomCenter = rotated_atom_centers.xyz;
    
    // Transform the model space coordinates to normalized device coordinates
    normalized_impostor_vertex.position = shadow_projection_matrix * rotated_model;

    // Return the processed vertex
    return normalized_impostor_vertex;
}

// MARK: - Fragment function

struct ShadowFragmentOut{
    float depth [[ depth(any) ]];
};

// [[stage_in]] uses the output from the basic_vertex vertex function
fragment ShadowFragmentOut shadow_fragment(ShadowVertexOut impostor_vertex [[stage_in]],
                                           const device FrameData& frameData [[ buffer(1) ]] ) {
    // Declare output
    ShadowFragmentOut output;

    // dot = x^2 + y^2
    half xy_squared_length = dot(impostor_vertex.billboardMapping, impostor_vertex.billboardMapping);
    
    // Discard pixels outside the sphere center (no need to do the sqrt)
    if (xy_squared_length > 1) {
        discard_fragment();
    }
    
    // Compute the normal in camera space
    half3 normal = half3(impostor_vertex.billboardMapping.x,
                         impostor_vertex.billboardMapping.y,
                         -sqrt(1.0 - xy_squared_length));
    
    // Compute the position of the fragment in world space
    float3 sphereWorldPosition = normal * impostor_vertex.atom_radius + impostor_vertex.atomCenter;

    // Recompute fragment depth
    simd_float4x4 orthogonalProjectionMatrix = frameData.shadowProjectionMatrix;
    float4 sphereClipPosition = ( orthogonalProjectionMatrix * float4(sphereWorldPosition.x,
                                                                      sphereWorldPosition.y,
                                                                      sphereWorldPosition.z,
                                                                      1.0) );
    // No need to divide by sphereClipPosition.w since after the orthogonal projection w will always be 1.0.
    // Also, a depth offset is added to avoid self-shadowing on small molecules (the output depth here being
    // just slightly too short and failing the depth comparison on the ImpostorShader).
    output.depth = sphereClipPosition.z + DEPTH_OFFSET;
    
    return output;
}
