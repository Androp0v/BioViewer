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

using namespace metal;

struct ShadowVertexOut{
    float4 position [[position]];
    float3 atomCenter;
    float2 billboardMapping;
    uint8_t atomType;
};

// MARK: - Vertex function

vertex ShadowVertexOut shadow_vertex(const device BillboardVertex *vertex_buffer [[ buffer(0) ]],
                                       const device int16_t *subunitIndex [[ buffer(1) ]],
                                       const device uint8_t *atomType [[ buffer(2) ]],
                                       const device FrameData& frameData [[ buffer(3) ]],
                                       unsigned int vid [[ vertex_id ]]) {

    // Initialize the returned VertexOut structure
    ShadowVertexOut normalized_impostor_vertex;
    int verticesPerAtom = 4;
    
    // Set attributes
    normalized_impostor_vertex.billboardMapping = vertex_buffer[vid].billboardMapping;
    normalized_impostor_vertex.atomType = atomType[vid / verticesPerAtom];

    // Fetch the matrices
    simd_float4x4 model_view_matrix = frameData.model_view_matrix;
    
    simd_float4x4 shadow_projection_matrix = frameData.shadowProjectionMatrix;
    simd_float4x4 sun_rotation_matrix = frameData.sun_rotation_matrix;
    simd_float4x4 inverse_sun_rotation_matrix = frameData.inverse_sun_rotation_matrix;
    
    // Rotate the model in world space
    float4 rotated_atom_centers = sun_rotation_matrix * float4(vertex_buffer[vid].atomCenter.x,
                                                               vertex_buffer[vid].atomCenter.y,
                                                               vertex_buffer[vid].atomCenter.z,
                                                               1.0);

    // To rotate the billboards so they are facing the screen, first rotate them like the model,
    // along the protein axis.
    float4 rotated_model = sun_rotation_matrix * float4(vertex_buffer[vid].position.x,
                                                                vertex_buffer[vid].position.y,
                                                                vertex_buffer[vid].position.z,
                                                                1.0);
    // Then translate the triangle to the origin of coordinates
    rotated_model.xyz = rotated_model.xyz - rotated_atom_centers.xyz;
    // Reverse the rotation by rotating in the opposite rotation along the billboard axis, NOT
    // the protein axis.
    rotated_model = inverse_sun_rotation_matrix * rotated_model;
    // Translate the triangles back to their positions, now that they're already rotated
    rotated_model.xyz = rotated_model.xyz + rotated_atom_centers.xyz;
    
    // Transform the world space coordinates to eye space coordinates
    float4 eye_position = model_view_matrix * rotated_model;
    
    // For the ShadowShader, we use model coordinates instead of camera coordinates
    normalized_impostor_vertex.atomCenter = rotated_atom_centers.xyz;
    
    // Transform the eye space coordinates to normalized device coordinates
    normalized_impostor_vertex.position = shadow_projection_matrix * eye_position;

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
    
    // Compute the position of the fragment in world space
    float3 sphereWorldPosition = (normal * atomRadius[impostor_vertex.atomType]) + impostor_vertex.atomCenter;
    
    // Recompute fragment depth
    simd_float4x4 orthogonalProjectionMatrix = frameData.shadowProjectionMatrix;
    float4 sphereClipPosition = ( orthogonalProjectionMatrix * float4(sphereWorldPosition.x,
                                                                      sphereWorldPosition.y,
                                                                      sphereWorldPosition.z,
                                                                      1.0) );
    // No need to divide by sphereClipPosition.w since after the orthogonal projection w will always be 1.0
    output.depth = sphereClipPosition.z;
    
    return output;
}
