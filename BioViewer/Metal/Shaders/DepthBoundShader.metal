//
//  DepthBoundShader.metal
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 25/5/22.
//

#include <metal_stdlib>
#include "FrameData.h"
#include "../Meshes/GeneratedVertex.h"
#include "../Meshes/AtomProperties.h"

using namespace metal;

struct DepthBoundVertexOut{
    float4 position [[position]];
};


// MARK: - Vertex function

vertex DepthBoundVertexOut depth_bound_vertex(const device BillboardVertex *vertex_buffer [[ buffer(0) ]],
                                            const device FrameData& frameData [[ buffer(1) ]],
                                            unsigned int vertex_id [[ vertex_id ]]) {

    // Initialize the returned VertexOut structure
    DepthBoundVertexOut normalized_impostor_vertex;
    
    // Fetch the matrices
    simd_float4x4 model_view_matrix = frameData.model_view_matrix;
    simd_float4x4 projectionMatrix = frameData.projectionMatrix;
    simd_float4x4 rotation_matrix = frameData.rotation_matrix;
    simd_float4x4 inverse_rotation_matrix = frameData.inverse_rotation_matrix;
    
    // Rotate the model in world space
    float4 rotated_atom_centers = rotation_matrix * float4(vertex_buffer[vertex_id].billboard_world_center.x,
                                                           vertex_buffer[vertex_id].billboard_world_center.y,
                                                           vertex_buffer[vertex_id].billboard_world_center.z,
                                                           1.0);

    // To rotate the billboards so they are facing the screen, first rotate them like the model,
    // along the protein axis.
    float4 rotated_model = rotation_matrix * float4(vertex_buffer[vertex_id].position.x,
                                                    vertex_buffer[vertex_id].position.y,
                                                    vertex_buffer[vertex_id].position.z,
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
        
    // Transform the eye space coordinates to normalized device coordinates
    normalized_impostor_vertex.position = projectionMatrix * eye_position;

    // Return the processed vertex
    return normalized_impostor_vertex;
}

// MARK: - Fragment function

struct DepthBoundFragmentOut{
    half4 color [[ color(0) ]];
};

// [[stage_in]] uses the output from the basic_vertex vertex function
fragment DepthBoundFragmentOut fragment_bound_vertex(DepthBoundVertexOut impostor_vertex [[stage_in]]) {
    
    // Declare output
    DepthBoundFragmentOut output;
    
    // Shade all shown fragments
    output.color = half4(1.0, 1.0, 1.0, 1.0);
    
    return output;
}