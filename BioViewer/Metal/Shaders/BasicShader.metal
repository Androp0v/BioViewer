//
//  BasicShader.metal
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 30/5/21.
//

#include <metal_stdlib>
#include <simd/simd.h>
#include "../Meshes/AtomProperties.h"

using namespace metal;

// MARK: - Data structures

struct VertexOut{
    float4 position [[position]];
    float4 color;
    float depth;
};

struct Uniforms{
    simd_float4x4 model_view_matrix;
    simd_float4x4 projectionMatrix;
    simd_float4x4 rotation_matrix;
};

// MARK: - Vertex function

vertex VertexOut basic_vertex(const device simd_float3* vertex_buffer [[ buffer(0) ]],
                              const device uint8_t *atomType [[ buffer(1) ]],
                              const device Uniforms& uniform_buffer [[ buffer(2) ]],
                              unsigned int vid [[ vertex_id ]]) {

    // Initialize the returned VertexOut structure
    VertexOut normalized_vertex;
    int verticesPerAtom = 12;

    // Fetch the matrices
    simd_float4x4 model_view_matrix = uniform_buffer.model_view_matrix;
    simd_float4x4 projectionMatrix = uniform_buffer.projectionMatrix;
    simd_float4x4 rotation_matrix = uniform_buffer.rotation_matrix;

    // Rotate the model in world space
    float4 rotated_model = rotation_matrix * float4(vertex_buffer[vid].x,
                                                    vertex_buffer[vid].y,
                                                    vertex_buffer[vid].z,
                                                    1.0);

    // Transform the world space coordinates to eye space coordinates
    float4 eye_position = model_view_matrix * rotated_model;

    // Transform the eye space coordinates to normalized device coordinates
    normalized_vertex.position = projectionMatrix * eye_position;

    // Color the atom based on the atom type
    normalized_vertex.color = atomColor[ atomType[vid / verticesPerAtom] ];

    // Depth is computed in eye space coordinates, not normalized device coordinates
    normalized_vertex.depth = eye_position.z;

    // Return the processed vertex
    return normalized_vertex;
}

// MARK: - Fragment function

// [[stage_in]] uses the output from the basic_vertex vertex function
fragment half4 basic_fragment(VertexOut normalized_vertex [[stage_in]]) {

    // Shade based on its depth value
    return half4(normalized_vertex.color.r - pow(normalized_vertex.depth, 2) / 2000000,
                 normalized_vertex.color.g - pow(normalized_vertex.depth, 2) / 2000000,
                 normalized_vertex.color.b - pow(normalized_vertex.depth, 2) / 2000000,
                 1.0);
}
