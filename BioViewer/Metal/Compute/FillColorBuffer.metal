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
                              const device uint8_t *atom_type [[ buffer(1) ]],
                              constant FillColorInput &color_input [[buffer(2)]],
                              uint i [[ thread_position_in_grid ]],
                              uint l [[ thread_position_in_threadgroup ]]) {
    
    // Fill with same color
    atom_color[i] = half3(1.0, 1.0, 1.0);
    
    if (color_input.colorBySubunit) {
        // Color the atom based on the subunit type
        // FIXME: RECOLOR
        // atom_color[i] = half4(color_input.atom_color[ subunitIndex[atom_id_configuration] ]);
    } else {
        // Color the atom based on the atom type
        atom_color[i] = half3( color_input.atom_color[atom_type[i]].rgb );
    }
}
