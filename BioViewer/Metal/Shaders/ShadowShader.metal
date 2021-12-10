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

struct ImpostorVertexOut{
    float4 position [[position]];
    float3 atomCenter;
    float2 billboardMapping;
    uint8_t atomType;
    float4 color;
};

// MARK: - Vertex function

vertex ImpostorVertexOut shadow_vertex(const device BillboardVertex *vertex_buffer [[ buffer(0) ]],
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
    simd_float4x4 rotation_matrix = frameData.rotation_matrix;
    simd_float4x4 inverse_rotation_matrix = frameData.inverse_rotation_matrix;
    
    simd_float4x4 shadow_projection_matrix = frameData.shadowProjectionMatrix;
    simd_float4x4 sun_rotation_matrix = frameData.sunRotationMatrix;
    simd_float4x4 inverse_sun_rotation_matrix = frameData.inverseSunRotationMatrix;
    
    // Rotate the model in world space
    float4 rotated_atom_centers = sun_rotation_matrix * rotation_matrix * float4(vertex_buffer[vid].atomCenter.x,
                                                                                 vertex_buffer[vid].atomCenter.y,
                                                                                 vertex_buffer[vid].atomCenter.z,
                                                                                 1.0);

    // To rotate the billboards so they are facing the screen, first rotate them like the model,
    // along the protein axis.
    float4 rotated_model = sun_rotation_matrix * rotation_matrix * float4(vertex_buffer[vid].position.x,
                                                                          vertex_buffer[vid].position.y,
                                                                          vertex_buffer[vid].position.z,
                                                                          1.0);
    // Then translate the triangle to the origin of coordinates
    rotated_model.xyz = rotated_model.xyz - rotated_atom_centers.xyz;
    // Reverse the rotation by rotating in the opposite rotation along the billboard axis, NOT
    // the protein axis.
    rotated_model =  inverse_rotation_matrix * inverse_sun_rotation_matrix * rotated_model;
    // Translate the triangles back to their positions, now that they're already rotated
    rotated_model.xyz = rotated_model.xyz + rotated_atom_centers.xyz;
    
    // Transform the world space coordinates to eye space coordinates
    float4 eye_position = model_view_matrix * rotated_model;
    
    // Transform the atom positions from world space to eye space
    normalized_impostor_vertex.atomCenter = (model_view_matrix * rotated_atom_centers).xyz;
    
    // Transform the eye space coordinates to normalized device coordinates
    normalized_impostor_vertex.position = shadow_projection_matrix * eye_position;
    
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

struct ShadowFragmentOut{
    float color [[ color(0) ]];
    float depth [[ depth(any) ]];
};

// [[stage_in]] uses the output from the basic_vertex vertex function
fragment ShadowFragmentOut shadow_fragment(ImpostorVertexOut impostor_vertex [[stage_in]],
                                           const device FrameData& frameData [[ buffer(1) ]] ) {
    // Declare output
    ShadowFragmentOut output;
    
    /*
    output.depth = 1.0;
    return output;
    */
    
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
    float3 sphereCameraPosition = (normal * atomRadius[impostor_vertex.atomType]) + impostor_vertex.atomCenter;
    
    // Move the point back to world coordinates
    simd_float4x4 inverse_model_view_matrix = frameData.inverse_model_view_matrix;
    float4 sphereWorldPosition = ( inverse_model_view_matrix * float4(sphereCameraPosition.x,
                                                                      sphereCameraPosition.y,
                                                                      sphereCameraPosition.z,
                                                                      1.0) );
    
    // Recompute fragment depth
    simd_float4x4 orthogonalProjectionMatrix = frameData.shadowProjectionMatrix;
    float4 sphereClipPosition = ( orthogonalProjectionMatrix * float4(sphereWorldPosition.x,
                                                                      sphereWorldPosition.y,
                                                                      sphereWorldPosition.z,
                                                                      1.0) );
    float normalizedDeviceCoordinatesDepth = sphereClipPosition.z / sphereClipPosition.w;
    output.depth = normalizedDeviceCoordinatesDepth;
    
    // Color
    output.color = normalizedDeviceCoordinatesDepth;
    
    return output;
}
