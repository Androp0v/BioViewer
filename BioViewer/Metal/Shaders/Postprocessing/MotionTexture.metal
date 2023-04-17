//
//  MotionTexture.metal
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 16/4/23.
//

#include <metal_stdlib>
#include "ReprojectionData.h"
using namespace metal;

kernel void motion_texture(constant ReprojectionData& reprojection_data [[ buffer(0) ]],
                           const texture2d<float, access::read> depth_output [[ texture(0) ]],
                           const texture2d<float, access::write> motion_texture [[ texture(1) ]],
                           uint2 texture_position [[ thread_position_in_grid ]]) {
    float4 motion_vector;
    float depth = depth_output.read(texture_position).r;
    if (depth == 1.0) {
        motion_vector = float4(0.0, 0.0, 0.0, 0.0);
    } else {
        float2 texture_position_normalized;
        texture_position_normalized.x = texture_position.x / reprojection_data.renderWidth;
        texture_position_normalized.y = texture_position.y / reprojection_data.renderHeight;
        float4 ndc_position = float4(2 * (texture_position_normalized.x - 0.5), -2 * (texture_position_normalized.y - 0.5), depth, 1.0);
        float3 old_ndc_position = (reprojection_data.reprojection_matrix * ndc_position).xyz;
        
        half2 old_texture_position = half2(old_ndc_position.x / 2 + 0.5, -old_ndc_position.y / 2 + 0.5);
        half2 old_texture_position_normalized;
        old_texture_position_normalized.x = old_texture_position.x / reprojection_data.renderWidth;
        old_texture_position_normalized.y = old_texture_position.y / reprojection_data.renderHeight;
        
        motion_vector = float4(half(texture_position_normalized.x) - old_texture_position_normalized.x,
                               half(texture_position_normalized.y) - old_texture_position_normalized.y,
                               0.0,
                               0.0);
    }
    motion_texture.write(motion_vector, texture_position);
}
