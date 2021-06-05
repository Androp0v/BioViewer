//
//  BasicShader.metal
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 30/5/21.
//

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// MARK: - Data structures

struct VertexOut{
    float4 position [[position]];
    float depth;
};

struct Uniforms{
    simd_float4x4 model_view_matrix;
    simd_float4x4 projectionMatrix;
    simd_float4x4 rotation_matrix;
};

// MARK: - Vertex function

vertex VertexOut basic_vertex(const device packed_float3* vertex_buffer [[ buffer(0) ]],
                              const device Uniforms& uniform_buffer [[ buffer(1) ]],
                              unsigned int vid [[ vertex_id ]]) {

    VertexOut normalized_vertex;
    simd_float4x4 model_view_matrix = uniform_buffer.model_view_matrix;
    simd_float4x4 projectionMatrix = uniform_buffer.projectionMatrix;
    simd_float4x4 rotation_matrix = uniform_buffer.rotation_matrix;

    float4 rotated_model = rotation_matrix * float4(vertex_buffer[vid].x,
                                                    vertex_buffer[vid].y,
                                                    vertex_buffer[vid].z,
                                                    1.0);
    float4 eye_position = model_view_matrix * rotated_model;

    normalized_vertex.position = projectionMatrix * eye_position;

    normalized_vertex.depth = normalized_vertex.position.z;
    return normalized_vertex;
}

// MARK: - Fragment function

// [[stage_in]] uses the output from the basic_vertex vertex function
fragment half4 basic_fragment(VertexOut normalized_vertex [[stage_in]]) {
    return half4(2.0 / ( (normalized_vertex.depth) - 8),
                 1.0 / ( (normalized_vertex.depth) - 8),
                 1.0 / ( (normalized_vertex.depth) - 8),
                 1.0);
}
