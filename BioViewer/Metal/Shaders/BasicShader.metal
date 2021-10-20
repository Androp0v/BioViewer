//
//  BasicShader.metal
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 30/5/21.
//

#include <metal_stdlib>
#include <simd/simd.h>
#include "FrameData.h"
#include "../Meshes/GeneratedVertex.h"

using namespace metal;

// MARK: - Data structures

struct VertexOut{
    float4 position [[position]];
    half3 normal;
    float4 color;
    float depth;
};

// MARK: - Vertex function

vertex VertexOut basic_vertex(const device GeneratedVertex* vertex_buffer [[ buffer(0) ]],
                              const device uint8_t *atomType [[ buffer(1) ]],
                              const device FrameData& frameData [[ buffer(2) ]],
                              unsigned int vid [[ vertex_id ]]) {

    // Initialize the returned VertexOut structure
    VertexOut normalized_vertex;
    int verticesPerAtom = 12;

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

    // Assign the normal to the VertexOut
    normalized_vertex.normal = half3( (rotation_matrix * float4(vertex_buffer[vid].normal.x,
                                                               vertex_buffer[vid].normal.y,
                                                               vertex_buffer[vid].normal.z,
                                                               1.0)).xyz );

    // Color the atom based on the atom type
    normalized_vertex.color = frameData.atomColor[ atomType[vid / verticesPerAtom] ];

    // Depth is computed in eye space coordinates, not normalized device coordinates
    normalized_vertex.depth = eye_position.z;

    // Return the processed vertex
    return normalized_vertex;
}

// MARK: - Fragment function

// [[stage_in]] uses the output from the basic_vertex vertex function
fragment half4 basic_fragment(VertexOut normalized_vertex [[stage_in]]) {

    // Phong diffuse shading
    half3 sunRayDirection = normalize(half3(1, 1, 0.0));
    half3 viewDirection = half3(0,0,-1);
    half reflectivity = 0.5;
    half specularExponent = 10;

    half3 shadedColor = half3(normalized_vertex.color.r,
                              normalized_vertex.color.g,
                              normalized_vertex.color.b);

    // Add Phong diffuse component
    shadedColor = shadedColor + dot(normalized_vertex.normal, sunRayDirection) * reflectivity;

    // Add Phong specular component

    half3 reflectedRay = 2 * dot(normalized_vertex.normal, sunRayDirection) * normalized_vertex.normal - sunRayDirection;
    shadedColor = shadedColor + pow( dot(viewDirection, reflectedRay), specularExponent);

    return half4(shadedColor.r,
                 shadedColor.g,
                 shadedColor.b,
                 normalized_vertex.color.a);
}
