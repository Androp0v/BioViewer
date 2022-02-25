//
//  FillColorBuffer.metal
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 22/1/22.
//

#include <metal_stdlib>
#include "FillColorInput.h"

using namespace metal;

kernel void fill_color_buffer(device half3 *atom_color [[ buffer(0) ]],
                              const device int16_t *subunitIndex [[ buffer(1) ]],
                              const device uint8_t *atom_type [[ buffer(2) ]],
                              constant FillColorInput &color_input [[buffer(3)]],
                              uint i [[ thread_position_in_grid ]],
                              uint l [[ thread_position_in_threadgroup ]]) {
    half3 final_color;
    final_color = pow(half3( color_input.element_color[atom_type[i]].rgb ), 2) * color_input.colorByElement;
    final_color += pow(half3( color_input.subunit_color[subunitIndex[i]].rgb), 2) * color_input.colorBySubunit;
    
    atom_color[i] = sqrt(final_color);
}
