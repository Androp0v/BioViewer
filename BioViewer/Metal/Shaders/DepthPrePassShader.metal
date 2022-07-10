//
//  DepthPrePassShader.metal
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 25/5/22.
//

#include <metal_stdlib>
#include "FrameData.h"
#include "ShaderCommon.h"
#include "../Meshes/GeneratedVertex.h"
#include "../Meshes/AtomProperties.h"

using namespace metal;

struct DepthPrePassVertexOut{
    float4 position [[position]];
};

// MARK: - Vertex function

vertex DepthPrePassVertexOut depth_pre_pass_vertex(const device simd_half2 *vertex_position [[ buffer(0) ]],
                                                   const device simd_float3 *billboard_world_center [[ buffer(1) ]],
                                                   constant FrameData& frameData [[ buffer(5) ]],
                                                   unsigned int vertex_id [[ vertex_id ]]) {

    // Initialize the returned DepthPrePassVertexOut structure
    DepthPrePassVertexOut normalized_depth_pre_pass_vertex;
    
    // Fetch the matrices
    simd_float4x4 model_view_matrix = frameData.model_view_matrix;
    simd_float4x4 projectionMatrix = frameData.projectionMatrix;
    simd_float4x4 rotation_matrix = frameData.rotation_matrix;
    
    // Rotate the model in world space
    float4 rotated_atom_centers = rotation_matrix * float4(billboard_world_center[vertex_id].xyz, 1.0);

    // Get the billboard vertex position, relative to the atom center
    half3 billboard_vertex = half3(vertex_position[vertex_id].xy, 0.0);
    
    // Now, make the billboards smaller for the depth pre-pass shader
    billboard_vertex.xyz = billboard_vertex.xyz * 0.70710678h;
    
    // Translate the triangles to their (rotated) world positions
    float4 billboard_vertex_world = float4(float3(billboard_vertex.xyz) + rotated_atom_centers.xyz, 1.0);
    
    // Transform the world space coordinates to eye space coordinates
    float4 eye_position = model_view_matrix * billboard_vertex_world;
    
    // Depth bias of 2 Armstrongs to avoid artifacts
    eye_position.z += 2; // FIXME: This introduces a perspective bug
        
    // Transform the eye space coordinates to normalized device coordinates
    normalized_depth_pre_pass_vertex.position = projectionMatrix * eye_position;

    // Return the processed vertex
    return normalized_depth_pre_pass_vertex;
}

// MARK: - Fragment function

// [[stage_in]] uses the output from the basic_vertex vertex function
fragment DepthPrePassFragmentOut depth_pre_pass_fragment(DepthPrePassVertexOut depth_pre_pass_vertex [[stage_in]]) {
    
    // Declare output
    DepthPrePassFragmentOut output;
    
    output.throwaway_color = half4(0, 0, 0, 0);
    output.bounded_depth = depth_pre_pass_vertex.position.z;
    
    return output;
}
