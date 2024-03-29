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
#define JITTERED_PCF
#define PENUMBRA_DEPENDENT_SAMPLING

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

float rand(int x, int y, int z) {
    int seed = x + y * 57 + z * 241;
    seed= (seed<< 13) ^ seed;
    return (( 1.0 - ( (seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
}

float InterleavedGradientNoise(float2 position_screen) {
    float3 magic = float3(0.06711056f, 0.00583715f, 52.9829189f);
    return fract(magic.z * fract(dot(position_screen, magic.xy)));
}

half2 OuterVogelDiskSample(half radius_scale, int sampleIndex, int samplesCount, float phi) {
    half GoldenAngle = 2.4f;

    half r = radius_scale;
    half theta = sampleIndex * GoldenAngle + phi;

    half2 sine_cosine;
    sine_cosine.x = sin(theta);
    sine_cosine.y = cos(theta);
  
    return half2(r * sine_cosine.y, r * sine_cosine.x);
}

half2 VogelDiskSample(half radius_scale, int sampleIndex, int samplesCount, float phi) {
    half GoldenAngle = 2.4f;

    half r = radius_scale * sqrt(sampleIndex + 0.5f) / sqrt(half(samplesCount));
    half theta = sampleIndex * GoldenAngle + phi;

    half2 sine_cosine;
    sine_cosine.x = sin(theta);
    sine_cosine.y = cos(theta);
  
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
    // int vertex_id_in_billboard = vertex_id - atom_id_configuration * 4;
    
    // Send vertex outside display bounds if disabled
    /*
    if (disabledAtoms[atom_id_configuration]) {
        normalized_impostor_vertex.position = float4(FLT_MAX, FLT_MAX, FLT_MAX, FLT_MAX);
        return normalized_impostor_vertex;
    }
    */
    
    // Set attributes
    normalized_impostor_vertex.billboardMapping = billboard_mapping[vertex_id];
    normalized_impostor_vertex.atom_radius = atom_radius[atom_id_configuration];

    // Fetch the matrices
    simd_float4x4 model_view_matrix = frameData.model_view_matrix;
    simd_float4x4 projectionMatrix = frameData.projectionMatrix;
    simd_float4x4 rotation_matrix = frameData.rotation_matrix;
    
    // Rotate the model in world space
    float4 rotated_atom_centers = rotation_matrix * float4(billboard_world_center[atom_id_configuration].xyz, 1.0);

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

// MARK: - Fragment function

struct ImpostorFragmentOut{
    half4 color [[ color(0) ]];
    float depth [[ depth(less) ]];
};

ImpostorFragmentOut impostor_fragment_common(ImpostorVertexOut impostor_vertex,
                                             constant FrameData &frameData,
                                             const depth2d<float> shadowMap,
                                             sampler shadowSampler,
                                             float prepass_depth) {
    // Declare output
    ImpostorFragmentOut output;
    
    // dot = x^2 + y^2
    half xy_squared_length = dot(impostor_vertex.billboardMapping, impostor_vertex.billboardMapping);
    
    // Discard pixels outside the sphere center (no need to do the sqrt)
    if (xy_squared_length > 1) {
        discard_fragment();
    }
    
    // Compute the normal in atom space
    half3 normal = half3(impostor_vertex.billboardMapping.x,
                         impostor_vertex.billboardMapping.y,
                         -sqrt(1.0 - xy_squared_length));
    
    // Compute the position of the fragment in camera space
    float3 spherePosition = (float3(normal) * impostor_vertex.atom_radius) + impostor_vertex.atomCenter;
    
    // Recompute fragment depth
    simd_float4x4 projectionMatrix = frameData.projectionMatrix;
    float4 sphereClipPosition = ( projectionMatrix * float4(spherePosition.x,
                                                            spherePosition.y,
                                                            spherePosition.z,
                                                            1.0) );
    float normalizedDeviceCoordinatesDepth = sphereClipPosition.z / sphereClipPosition.w;
    if (normalizedDeviceCoordinatesDepth > prepass_depth) {
        discard_fragment();
    }
    output.depth = normalizedDeviceCoordinatesDepth;
    
    // Phong diffuse shading
    half3 sunRayDirection = half3(frameData.sun_direction);
    half reflectivity = 0.3;
    
    // Add base color
    half3 shadedColor = impostor_vertex.color.rgb;
    
    // Compute Phong diffuse component
    half phongDiffuse = dot(normal, sunRayDirection) * reflectivity;
    shadedColor = saturate(shadedColor + phongDiffuse);
        
    // Depth cueing
    if (frameData.has_depth_cueing) {
        // Rescale depth so only the part of the model that has a depth ranging 0.5 to 1.0
        // (the furthest half of the model) gets depth cued.
        float rescaled_depth = max((2.0 * normalizedDeviceCoordinatesDepth) - 1.0, 0.0);
        shadedColor.rgb *= (1 - frameData.depth_cueing_strength * half3(rescaled_depth));
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
        shadedColor.rgb *= (1 - frameData.shadow_strength * (1 - is_sunlit));
        #else
        float sunlit_fraction = 0;
        int sample_count;
        if (is_high_quality_frame) {
            sample_count = 256;
        } else {
            sample_count = 4;
        }
        #ifndef JITTERED_PCF
        for (int sample_index = 0; sample_index < sample_count; sample_index++) {
            // FIXME: 0.001 should be proportional to the typical atom size
            half2 sample_offset = VogelDiskSample(0.001,
                                                  sample_index,
                                                  sample_count,
                                                  3);
            sunlit_fraction += shadowMap.sample_compare(shadowSampler,
                                                        sphereShadowClipPosition.xy + float2(sample_offset),
                                                        sphereShadowClipPosition.z);
        }
        #else
        float random_phi = InterleavedGradientNoise(impostor_vertex.position.xy);
        for (int sample_index = 0; sample_index < sample_count; sample_index++) {
            // FIXME: 0.001 should be proportional to the typical atom size
            half2 sample_offset = OuterVogelDiskSample(0.001,
                                                       sample_index,
                                                       sample_count,
                                                       random_phi);
            sunlit_fraction += shadowMap.sample_compare(shadowSampler,
                                                        sphereShadowClipPosition.xy + float2(sample_offset),
                                                        sphereShadowClipPosition.z);
        }
        #endif
        
        #ifdef PENUMBRA_DEPENDENT_SAMPLING
        if (sunlit_fraction != 0 && sunlit_fraction != sample_count) {
            for (int sample_index = 4; sample_index < 16; sample_index++) {
                // FIXME: 0.001 should be proportional to the typical atom size
                half2 sample_offset = VogelDiskSample(0.0005,
                                                      sample_index,
                                                      sample_count,
                                                      random_phi);
                sunlit_fraction += shadowMap.sample_compare(shadowSampler,
                                                            sphereShadowClipPosition.xy + float2(sample_offset),
                                                            sphereShadowClipPosition.z);
            }
            // Add the shadow to the shadedColor by subtracting color
            shadedColor.rgb *= (1 - frameData.shadow_strength * (1 - sunlit_fraction / (sample_count + 16)));
        } else {
            // Add the shadow to the shadedColor by subtracting color
            shadedColor.rgb *= (1 - frameData.shadow_strength * (1 - sunlit_fraction / sample_count));
        }
        #else
        // Add the shadow to the shadedColor by subtracting color
        shadedColor.rgb *= (1 - frameData.shadow_strength * (1 - sunlit_fraction / sample_count));
        #endif
        #endif
    }
    
    // Final color
    output.color = half4(shadedColor.rgb, 1.0);
    
    return output;
}

// [[stage_in]] uses the output from the basic_vertex vertex function
fragment ImpostorFragmentOut impostor_fragment(ImpostorVertexOut impostor_vertex [[stage_in]],
                                               constant FrameData &frameData [[ buffer(1) ]],
                                               const depth2d<float> shadowMap [[ texture(1) ]],
                                               sampler shadowSampler [[ sampler(0) ]],
                                               DepthPrePassFragmentOut depth_pre_pass_output) {
    // Depth testing with precomputed depth upper bound
    float bounded_depth = 1.0;
    if (!is_high_quality_frame) {
        bounded_depth = depth_pre_pass_output.bounded_depth; // FIXME: Rename to depth
        float primitiveDepth = impostor_vertex.position.z;
        if (bounded_depth + frameData.depth_bias < primitiveDepth) {
            discard_fragment();
        }
    }
    return impostor_fragment_common(impostor_vertex, frameData, shadowMap, shadowSampler, bounded_depth);
}

fragment ImpostorFragmentOut impostor_fragment_no_prepass(ImpostorVertexOut impostor_vertex [[stage_in]],
                                                          constant FrameData &frameData [[ buffer(1) ]],
                                                          const depth2d<float> shadowMap [[ texture(1) ]],
                                                          sampler shadowSampler [[ sampler(0) ]]) {
    return impostor_fragment_common(impostor_vertex, frameData, shadowMap, shadowSampler, 1.0);
}
