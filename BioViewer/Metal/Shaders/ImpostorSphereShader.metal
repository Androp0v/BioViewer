//
//  ImpostorSphereShader.metal
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 29/10/21.
//

#include <metal_stdlib>
#include "FrameData.h"
#include "ShaderCommon.h"
#include "../Meshes/GeneratedVertex.h"
#include "../Meshes/AtomProperties.h"

#define PERCENTAGE_CLOSE_FILTERING

using namespace metal;

struct ImpostorVertexOut{
    float4 position [[position]];
    float3 atomCenter [[attribute(0)]];
    half2 billboardMapping [[attribute(1)]];
    half atom_radius [[attribute(2)]];
    half3 color [[attribute(3)]];
};

// MARK: - Build constants
constant bool is_high_quality_frame [[ function_constant(0) ]];

// MARK: - Functions

half2 VogelDiskSample(half radius_scale, int sampleIndex, int samplesCount, float phi) {
    half GoldenAngle = 2.4f;

    half r = radius_scale * sqrt(sampleIndex + 0.5f) / sqrt(half(samplesCount));
    half theta = sampleIndex * GoldenAngle + phi;

    half2 sine_cosine;
    sincos(theta, sine_cosine);
  
    return half2(r * sine_cosine.y, r * sine_cosine.x);
}


// MARK: - Vertex function

vertex ImpostorVertexOut impostor_vertex(const device simd_half2 *vertex_position [[ buffer(0) ]],
                                         const device simd_float3 *billboard_world_center [[ buffer(1) ]],
                                         const device simd_half2 *billboard_mapping [[ buffer(2) ]],
                                         const device half *atom_radius [[ buffer(3) ]],
                                         const device half3 *atomColor [[ buffer(4) ]],
                                         constant FrameData& frameData [[ buffer(5) ]],
                                         unsigned int vertex_id [[ vertex_id ]]) {

    // Initialize the returned VertexOut structure
    ImpostorVertexOut normalized_impostor_vertex;
    int verticesPerAtom = 4;
    int atom_id_configuration = (vertex_id / verticesPerAtom) % frameData.atoms_per_configuration;
    
    // Send vertex outside display bounds if disabled
    /*
    if (disabledAtoms[atom_id_configuration]) {
        normalized_impostor_vertex.position = float4(FLT_MAX, FLT_MAX, FLT_MAX, FLT_MAX);
        return normalized_impostor_vertex;
    }
    */
    
    // Set attributes
    normalized_impostor_vertex.billboardMapping = billboard_mapping[vertex_id];
    normalized_impostor_vertex.atom_radius = atom_radius[vertex_id];

    // Fetch the matrices
    simd_float4x4 model_view_matrix = frameData.model_view_matrix;
    simd_float4x4 projectionMatrix = frameData.projectionMatrix;
    simd_float4x4 rotation_matrix = frameData.rotation_matrix;
    
    // Rotate the model in world space
    float4 rotated_atom_centers = rotation_matrix * float4(billboard_world_center[vertex_id].xyz, 1.0);

    // Get the billboard vertex position, relative to the atom center
    float4 billboard_vertex = float4(float2(vertex_position[vertex_id].xy), 0.0, 1.0);
    
    // Translate the triangles to their (rotated) world positions
    billboard_vertex.xyz = billboard_vertex.xyz + rotated_atom_centers.xyz;
    
    // Transform the world space coordinates to eye space coordinates
    float4 eye_position = model_view_matrix * billboard_vertex;
    
    // Transform the atom positions from world space to eye space
    normalized_impostor_vertex.atomCenter = (model_view_matrix * rotated_atom_centers).xyz;
    
    // Transform the eye space coordinates to normalized device coordinates
    normalized_impostor_vertex.position = projectionMatrix * eye_position;
    
    // Set atom base color
    normalized_impostor_vertex.color = atomColor[atom_id_configuration];

    // Return the processed vertex
    return normalized_impostor_vertex;
}

// MARK: - Mesh Object Stage function

struct MeshObjectOutput{
    float4 position [[position]];
    half2 billboardMapping;
};

struct payload_t
{
    MeshObjectOutput vertices[4];
    float3 atomCenter;
    half atom_radius;
    half3 color;
    
    uint8_t primitiveCount;
    uint8_t vertexCount;
    uint8_t indices[6];
};

[[object]]
void impostorMeshObjectStageFunction(object_data payload_t &payload [[payload]],
                                     mesh_grid_properties meshGridProperties,
                                     const device simd_float3 *billboard_world_center [[ buffer(1) ]],
                                     const device half *atom_radius [[ buffer(3) ]],
                                     const device half3 *atomColor [[ buffer(4) ]],
                                     device float4 *debugOutput [[ buffer(30)]],
                                     constant FrameData& frameData [[ buffer(5) ]],
                                     uint3 positionInGrid [[threadgroup_position_in_grid]]) {
    
    uint atom_index = positionInGrid.x;
    
    // Set attributes
    payload.vertices[0].billboardMapping = simd_half2(1, 1);
    payload.vertices[1].billboardMapping = simd_half2(-1, 1);
    payload.vertices[2].billboardMapping = simd_half2(-1, -1);
    payload.vertices[3].billboardMapping = simd_half2(1, -1);
    
    // Set color and radius
    half radius = atom_radius[atom_index];
    payload.atom_radius = radius;
    payload.color = atomColor[atom_index];
    
    // Fetch the matrices
    simd_float4x4 model_view_matrix = frameData.model_view_matrix;
    // FIXME:
    /*
    model_view_matrix = simd_float4x4(
                                      simd_float4(1, 0, 0, 0),
                                      simd_float4(0, 1, 0, 0),
                                      simd_float4(0, 0, 1, 0),
                                      simd_float4(0, 0, 57.60942, 1)
                                      );
     */
    simd_float4x4 projectionMatrix = frameData.projectionMatrix;
    // FIXME:
    /*
    projectionMatrix = simd_float4x4(
                                     simd_float4(9.129419, 0.0, 0.0, 0.0),
                                     simd_float4(0.0, 9.237875, 0.0, 0.0),
                                     simd_float4(0.0, 0.0, 5.145922, -1.0),
                                     simd_float4(0.0, 0.0, -247.48123, 0.0)
                                     );
     */
    simd_float4x4 rotation_matrix = frameData.rotation_matrix;
    
    // Rotate the model in world space
    float4 rotated_atom_centers = rotation_matrix * float4(billboard_world_center[atom_index].xyz, 1.0);
    
    // Get the billboard vertex position, relative to the atom center
    float4 billboard_vertex[4];
    billboard_vertex[0] = float4(radius, radius, 0.0, 1.0);
    billboard_vertex[1] = float4(-radius, radius, 0.0, 1.0);
    billboard_vertex[2] = float4(-radius, -radius, 0.0, 1.0);
    billboard_vertex[3] = float4(radius, -radius, 0.0, 1.0);
    
    // Translate the triangles to their (rotated) world positions
    for (int i = 0; i < 4; i++) {
        billboard_vertex[i].xyz = billboard_vertex[i].xyz + rotated_atom_centers.xyz;
    }
    
    // Transform the world space coordinates to eye space coordinates
    float4 eye_position[4];
    for (int i = 0; i < 4; i++) {
        // Transform the world space coordinates to eye space coordinates
        eye_position[i] = model_view_matrix * billboard_vertex[i];
    }
    
    // Transform the atom positions from world space to eye space
    payload.atomCenter = (model_view_matrix * rotated_atom_centers).xyz;
    
    // Transform the eye space coordinates to normalized device coordinates
    for (int i = 0; i < 4; i++) {
        payload.vertices[i].position = projectionMatrix * eye_position[i];
    }
    debugOutput[atom_index] = float4(1.0, 1.0, 1.0, 1.0);
    // FIXME:
    /*
    payload.vertices[0].position = float4((rotated_atom_centers.xy + float2(0.25, 0.25)).xy, 0.5, 1.0);
    payload.vertices[1].position = float4((rotated_atom_centers.xy + float2(-0.25, 0.25)).xy, 0.5, 1.0);
    payload.vertices[2].position = float4((rotated_atom_centers.xy + float2(-0.25, -0.25)).xy, 0.5, 1.0);
    payload.vertices[3].position = float4((rotated_atom_centers.xy + float2(0.25, -0.25)).xy, 0.5, 1.0);
     */
    /*
    payload.vertices[0].position.z = 0.5;
    payload.vertices[0].position.x = 0.0;
    payload.vertices[0].position.y = 0.0;
    payload.vertices[1].position.z = 0.5;
    payload.vertices[2].position.z = 0.5;
    payload.vertices[3].position.z = 0.5;
     */

    // Set the indices
    
    // Triangle 1
    payload.indices[0] = 0;
    payload.indices[1] = 2;
    payload.indices[2] = 1;
    
    // Triangle 2
    payload.indices[3] = 2;
    payload.indices[4] = 0;
    payload.indices[5] = 3;
    
    // Mesh properties
    
    // Output is a quad, only 2 triangles
    payload.primitiveCount = 2;
    // Output is a quad, only 4 vertices
    payload.vertexCount = 4;
    
    // Set the output submesh count for the mesh shader.
    // Because the mesh shader is only producing one mesh, the threadgroup grid size is 1 x 1 x 1.
    meshGridProperties.set_threadgroups_per_grid(uint3(1, 1, 1));
}

// MARK: - Mesh Mesh Stage function

// Per-vertex output
struct MeshVertexOut{
    float4 position [[position]];
    half2 billboardMapping;
};

// Per-primitive output
struct MeshPrimitiveOut{
    float3 atomCenter;
    half atom_radius;
    half3 color;
};

[[mesh]]
void impostorMeshShaderMeshStageFunction(metal::mesh<MeshVertexOut, MeshPrimitiveOut, 4, 2, metal::topology::triangle> output,
                                         const object_data payload_t& payload [[payload]],
                                         uint lid [[thread_index_in_threadgroup]]) {
    // Set the number of primitives for the entire mesh.
    output.set_primitive_count(payload.primitiveCount);
    
    // Set vertex data
    if (lid < payload.vertexCount) {
        MeshVertexOut vertex_out;
        vertex_out.position = payload.vertices[lid].position;
        vertex_out.billboardMapping = payload.vertices[lid].billboardMapping;
        output.set_vertex(lid, vertex_out);
    }
    
    // Set primitive data
    if (lid < payload.primitiveCount) {
        MeshPrimitiveOut primitive_out;
        primitive_out.atomCenter = payload.atomCenter;
        primitive_out.atom_radius = payload.atom_radius;
        primitive_out.color = payload.color;
        output.set_primitive(lid, primitive_out);
        
        // Set the output indices.
        uint i = (3*lid);
        output.set_index(i+0, payload.indices[i+0]);
        output.set_index(i+1, payload.indices[i+1]);
        output.set_index(i+2, payload.indices[i+2]);
    }
}

// MARK: - Fragment function

struct ImpostorFragmentOut{
    half4 color [[ color(0) ]];
    float depth [[ depth(less) ]];
};

ImpostorFragmentOut impostor_fragment_common(ImpostorVertexOut impostor_vertex,
                                             constant FrameData &frameData,
                                             const depth2d<float> shadowMap,
                                             sampler shadowSampler) {
    // Declare output
    ImpostorFragmentOut output;
    
    // dot = x^2 + y^2
    half xy_squared_length = dot(impostor_vertex.billboardMapping, impostor_vertex.billboardMapping);
    
    // Discard pixels outside the sphere center (no need to do the sqrt)
    if (xy_squared_length > 1) {
        discard_fragment();
    }
    
    // Phong diffuse shading
    half3 sunRayDirection = half3(0.7071067812, 0.7071067812, 0);
    half reflectivity = 0.3;
    
    // Add base color
    half3 shadedColor = impostor_vertex.color.rgb;
    
    // Compute the normal in atom space
    half3 normal = half3(impostor_vertex.billboardMapping.x,
                         impostor_vertex.billboardMapping.y,
                         -sqrt(1.0 - xy_squared_length));
    
    // Compute the position of the fragment in camera space
    float3 spherePosition = (float3(normal) * impostor_vertex.atom_radius) + impostor_vertex.atomCenter;
    
    // Compute Phong diffuse component
    half phongDiffuse = dot(normal, sunRayDirection) * reflectivity;
    shadedColor = saturate(shadedColor + phongDiffuse);
    
    // Recompute fragment depth
    simd_float4x4 projectionMatrix = frameData.projectionMatrix;
    float4 sphereClipPosition = ( projectionMatrix * float4(spherePosition.x,
                                                            spherePosition.y,
                                                            spherePosition.z,
                                                            1.0) );
    float normalizedDeviceCoordinatesDepth = sphereClipPosition.z / sphereClipPosition.w;
    output.depth = normalizedDeviceCoordinatesDepth;
    
    // Depth cueing
    if (frameData.has_depth_cueing) {
        // Rescale depth so only the part of the model that has a depth ranging 0.5 to 1.0
        // (the furthest half of the model) gets depth cued.
        float rescaled_depth = max((2.0 * normalizedDeviceCoordinatesDepth) - 1.0, 0.0);
        shadedColor.rgb -= frameData.depth_cueing_strength * half3(rescaled_depth);
    }
    
    // Add hard shadows
    if (frameData.has_shadows) {
        
        simd_float4x4 camera_to_shadow_projection_matrix = frameData.camera_to_shadow_projection_matrix;
        float3 sphereShadowClipPosition = ( camera_to_shadow_projection_matrix * float4(spherePosition.x,
                                                                                        spherePosition.y,
                                                                                        spherePosition.z,
                                                                                        1.0)).xyz;
        
        // When calculating texture coordinates to sample from shadow map, flip the y/t coordinate and
        // convert from the [-1, 1] range of clip coordinates to [0, 1] range of
        // used for texture sampling
        sphereShadowClipPosition.y *= -1;
        sphereShadowClipPosition.xy += 1.0;
        sphereShadowClipPosition.xy /= 2;
        
        #ifndef PERCENTAGE_CLOSE_FILTERING
        float shadow_sample = shadowMap.sample_compare(shadowSampler,
                                                       sphereShadowClipPosition.xy,
                                                       sphereShadowClipPosition.z);
            
        bool is_sunlit = false;
        if (shadow_sample > 0) {
            is_sunlit = true;
        }
        
        // Add the shadow to the shadedColor by subtracting color
        shadedColor.rgb -= frameData.shadow_strength * (1 - is_sunlit);
        #else
        float sunlit_fraction = 0;
        int sample_count;
        if (is_high_quality_frame) {
            sample_count = 128;
        } else {
            sample_count = 2;
        }
        for (int sample_index = 0; sample_index < sample_count; sample_index++) {
            // FIXME: 0.001 should be proportional to the typical atom size
            // TO-DO: VogelDiskSample may be called with a random number instead of 3 for the rotation
            half2 sample_offset = VogelDiskSample(0.001, sample_index, sample_count, 3);
            sunlit_fraction += shadowMap.sample_compare(shadowSampler,
                                                        sphereShadowClipPosition.xy + float2(sample_offset),
                                                        sphereShadowClipPosition.z);
        }
        
        // Add the shadow to the shadedColor by subtracting color
        shadedColor.rgb -= frameData.shadow_strength * (1 - sunlit_fraction / sample_count);
        #endif
    }
    
    // Final color
    output.color = half4(shadedColor.rgb, 1.0);
    
    return output;
}

struct MeshFragmentIn
{
    MeshVertexOut vertex_out;
    MeshPrimitiveOut primitive_out;
};

// [[stage_in]] uses the output from the basic_vertex vertex function
fragment ImpostorFragmentOut impostor_fragment_mesh(MeshFragmentIn impostor_mesh_vertex [[stage_in]],
                                                    constant FrameData &frameData [[ buffer(1) ]],
                                                    const depth2d<float> shadowMap [[ texture(1) ]],
                                                    sampler shadowSampler [[ sampler(0) ]]
                                                    // FIXME: DepthPrePassFragmentOut depth_pre_pass_output) {
                                                    ) {
    // FIXME: Re-implement this
    /*
    // Depth testing with precomputed depth upper bound
    if (!is_high_quality_frame) {
        float boundedDepth = depth_pre_pass_output.bounded_depth; // FIXME: Rename to depth
        float primitiveDepth = impostor_mesh_vertex.vertex_out.position.z;
        if (boundedDepth + frameData.depth_bias < primitiveDepth) {
            discard_fragment();
        }
    }
    // FIXME:

    ImpostorVertexOut workaroundVertex;
    
    workaroundVertex.position = impostor_mesh_vertex.vertex_out.position;
    workaroundVertex.billboardMapping = impostor_mesh_vertex.vertex_out.billboardMapping;
    
    workaroundVertex.atom_radius = impostor_mesh_vertex.primitive_out.atom_radius;
    workaroundVertex.atomCenter = impostor_mesh_vertex.primitive_out.atomCenter;
    workaroundVertex.color = impostor_mesh_vertex.primitive_out.color;
    
    return impostor_fragment_common(workaroundVertex, frameData, shadowMap, shadowSampler);
     */
    ImpostorFragmentOut fragment_out;
    fragment_out.color = half4(impostor_mesh_vertex.vertex_out.position.y / 1000, 0.0, 1.0, 1.0);
    fragment_out.depth = impostor_mesh_vertex.vertex_out.position.z;
    return fragment_out;
}

// [[stage_in]] uses the output from the basic_vertex vertex function
fragment ImpostorFragmentOut impostor_fragment(ImpostorVertexOut impostor_vertex [[stage_in]],
                                               constant FrameData &frameData [[ buffer(1) ]],
                                               const depth2d<float> shadowMap [[ texture(1) ]],
                                               sampler shadowSampler [[ sampler(0) ]],
                                               DepthPrePassFragmentOut depth_pre_pass_output) {
    // Depth testing with precomputed depth upper bound
    if (!is_high_quality_frame) {
        float boundedDepth = depth_pre_pass_output.bounded_depth; // FIXME: Rename to depth
        float primitiveDepth = impostor_vertex.position.z;
        if (boundedDepth + frameData.depth_bias < primitiveDepth) {
            discard_fragment();
        }
    }
    return impostor_fragment_common(impostor_vertex, frameData, shadowMap, shadowSampler);
}

fragment ImpostorFragmentOut impostor_fragment_no_prepass(ImpostorVertexOut impostor_vertex [[stage_in]],
                                                          constant FrameData &frameData [[ buffer(1) ]],
                                                          const depth2d<float> shadowMap [[ texture(1) ]],
                                                          sampler shadowSampler [[ sampler(0) ]]) {
    return impostor_fragment_common(impostor_vertex, frameData, shadowMap, shadowSampler);
}


