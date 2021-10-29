//
//  ImpostorSphereShader.metal
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 29/10/21.
//

#include <metal_stdlib>
#include "FrameData.h"
#include "../Meshes/GeneratedVertex.h"

using namespace metal;

struct ImpostorVertexOut{
    float4 position [[position]];
    float4 color;
};

// MARK: - Vertex function

vertex ImpostorVertexOut impostor_vertex(const device BillboardVertex* vertex_buffer [[ buffer(0) ]],
                                         const device uint8_t *atomType [[ buffer(1) ]],
                                         const device FrameData& frameData [[ buffer(2) ]],
                                         unsigned int vid [[ vertex_id ]]) {

    // Initialize the returned VertexOut structure
    ImpostorVertexOut normalized_vertex;
    int verticesPerAtom = 4;

    // Fetch the matrices
    simd_float4x4 model_view_matrix = frameData.model_view_matrix;
    simd_float4x4 projectionMatrix = frameData.projectionMatrix;
    simd_float4x4 rotation_matrix = frameData.rotation_matrix;

    // Rotate the model in world space
    float4 rotated_model = rotation_matrix * float4(vertex_buffer[vid].position.x,
                                                    vertex_buffer[vid].position.y,
                                                    vertex_buffer[vid].position.z,
                                                    1.0);

    // Transform the world space coordinates to eye space coordinates
    float4 eye_position = model_view_matrix * rotated_model;

    // Transform the eye space coordinates to normalized device coordinates
    normalized_vertex.position = projectionMatrix * eye_position;

    // Color the atom based on the atom type
    normalized_vertex.color = frameData.atomColor[ atomType[vid / verticesPerAtom] ];

    // Return the processed vertex
    return normalized_vertex;
}

// MARK: - Fragment function

// [[stage_in]] uses the output from the basic_vertex vertex function
fragment half4 impostor_fragment(ImpostorVertexOut impostor_vertex [[stage_in]]) {

    half3 shadedColor = half3(impostor_vertex.color.r,
                              impostor_vertex.color.g,
                              impostor_vertex.color.b);
    
    if (false) {
        discard_fragment();
    }

    return half4(shadedColor.r,
                 shadedColor.g,
                 shadedColor.b,
                 impostor_vertex.color.a);
}

