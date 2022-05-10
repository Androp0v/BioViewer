//
//  DebugPointShader.metal
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/5/22.
//

#include <metal_stdlib>
#include "../FrameData.h"
#include "../../Meshes/GeneratedVertex.h"
#include "../../Meshes/AtomProperties.h"
using namespace metal;

struct DebugVertexOut{
    float4 position [[position]];
    float point_size [[point_size]];
};

// MARK: - Vertex function

vertex DebugVertexOut debug_point_vertex(const device DebugPoint *vertex_buffer [[ buffer(0) ]],
                                         const device FrameData& frameData [[ buffer(1) ]],
                                         unsigned int vertex_id [[ vertex_id ]]) {

    // Initialize the returned VertexOut structure
    DebugVertexOut output_vertex;
    DebugPoint current_vertex = vertex_buffer[vertex_id];
    
    // Fetch the matrices
    simd_float4x4 model_view_matrix = frameData.model_view_matrix;
    simd_float4x4 projectionMatrix = frameData.projectionMatrix;
    simd_float4x4 rotation_matrix = frameData.rotation_matrix;
    
    // Rotate the model in world space
    float4 rotated_vertex = rotation_matrix * float4(current_vertex.position.x,
                                                     current_vertex.position.y,
                                                     current_vertex.position.z,
                                                     1.0);
    
    // Transform the world space coordinates to eye space coordinates
    float4 eye_position = model_view_matrix * rotated_vertex;
    
    // Transform the eye space coordinates to normalized device coordinates
    output_vertex.position = projectionMatrix * eye_position;
    
    // Change point size
    output_vertex.point_size = 1.0;
    
    // Return the processed vertex
    return output_vertex;
}

// MARK: - Fragment function

struct DebugFragmentOut {
    half4 color [[ color(0) ]];
};

// [[stage_in]] uses the output from the basic_vertex vertex function
fragment DebugFragmentOut debug_point_fragment(DebugVertexOut impostor_vertex [[stage_in]],
                                               const device FrameData &frameData [[ buffer(1) ]]) {
    
    DebugFragmentOut output;
    output.color = half4(1.0, 0.5, 0.5, 1.0);
    
    return output;
}
