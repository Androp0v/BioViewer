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

vertex DepthBoundVertexOut depth_bound_vertex(const device simd_half3 *vertex_position [[ buffer(0) ]],
                                              const device simd_float3 *billboard_world_center [[ buffer(1) ]],
                                              const device FrameData& frameData [[ buffer(2) ]],
                                              unsigned int vertex_id [[ vertex_id ]]) {

    // Initialize the returned DepthBoundVertexOut structure
    DepthBoundVertexOut normalized_depth_bound_vertex;
    
    // Fetch the matrices
    simd_float4x4 model_view_matrix = frameData.model_view_matrix;
    simd_float4x4 projectionMatrix = frameData.projectionMatrix;
    simd_float4x4 rotation_matrix = frameData.rotation_matrix;
    
    // Rotate the model in world space
    float4 rotated_atom_centers = rotation_matrix * float4(billboard_world_center[vertex_id].xyz, 1.0);

    // Get te billboard vertex position, relative to the atom center
    half3 billboard_vertex = vertex_position[vertex_id].xyz;
    
    // Now, make the billboards smaller for the depth-bound shader
    billboard_vertex.xyz = billboard_vertex.xyz * 0.70710678h;
    
    // Translate the triangles to their (rotated) world positions
    float4 billboard_vertex_world = float4(float3(billboard_vertex.xyz) + rotated_atom_centers.xyz, 1.0);
    
    // Transform the world space coordinates to eye space coordinates
    float4 eye_position = model_view_matrix * billboard_vertex_world;
    
    // Depth bias of 2 Armstrongs to avoid artifacts
    eye_position.z += 2; // FIXME: This introduces a perspective bug
        
    // Transform the eye space coordinates to normalized device coordinates
    normalized_depth_bound_vertex.position = projectionMatrix * eye_position;

    // Return the processed vertex
    return normalized_depth_bound_vertex;
}

// MARK: - Fragment function

struct DepthBoundFragmentOut{
    uint color [[ color(0) ]];
};

// [[stage_in]] uses the output from the basic_vertex vertex function
fragment DepthBoundFragmentOut depth_bound_fragment(DepthBoundVertexOut depth_bound_vertex [[stage_in]]) {
    
    // Declare output
    DepthBoundFragmentOut output;
    
    output.color = 0;
    
    return output;
}
