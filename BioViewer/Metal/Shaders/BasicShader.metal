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
};

struct Uniforms{
    simd_float4x4 rotationMatrix;
};

// MARK: - Vertex function

vertex VertexOut basic_vertex(const device packed_float3* vertex_buffer [[ buffer(0) ]],
                              const device Uniforms& uniform_buffer [[ buffer(1) ]],
                              unsigned int vid [[ vertex_id ]]) {

    VertexOut normalized_vertex;
    simd_float4x4 rotationMatrix = uniform_buffer.rotationMatrix;
    normalized_vertex.position = rotationMatrix * float4(vertex_buffer[vid].x,
                                                         vertex_buffer[vid].y,
                                                         vertex_buffer[vid].z,
                                                         2.0);
    normalized_vertex.position.z += 1.0;
    return normalized_vertex;
}

// MARK: - Fragment function

fragment half4 basic_fragment(VertexOut normalized_vertex [[stage_in]]) {

    return half4(0.35 / (normalized_vertex.position.z + 0.3),
                 0.35 / (normalized_vertex.position.z + 0.3),
                 0.35 / (normalized_vertex.position.z + 0.3),
                 1.0);
}
