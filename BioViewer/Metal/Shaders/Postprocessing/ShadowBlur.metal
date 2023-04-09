//
//  ShadowBlur.metal
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 9/4/23.
//

#include <metal_stdlib>
using namespace metal;

kernel void shadow_blur(const texture2d<float, access::read_write> renderer_output [[ texture(0) ]],
                        uint2 texture_position [[ thread_position_in_grid ]]) {
    // TODO: This kernel thing
    float4 source_color = float4(0.0, 0.0, 0.0, 0.0);
    for (int i = 0; i < 7; i++) {
        for (int j = 0; j < 7; j++) {
            uint2 sample_position = texture_position;
            sample_position.x += i;
            sample_position.y += j;
            source_color += renderer_output.read(sample_position);
        }
    }
    renderer_output.write(source_color / 49, texture_position);
}
