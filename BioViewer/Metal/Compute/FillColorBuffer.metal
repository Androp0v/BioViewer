//
//  FillColorBuffer.metal
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 22/1/22.
//

#include <metal_stdlib>
#include "FillColorInput.h"

using namespace metal;

half3 add_color_fraction(float3 base_color, float fraction) {
    // NOTE: To blend the colors we 'should' use the standard Gamma of 2.2. Instead
    // we square the numbers and take the square root, which is the same as using a
    // Gamma of 2.0. However, since the final color is the same, and it looks close
    // enough, we use the square/square root 'trick', since the pow([...], 2) is
    // likely compiler-optimized to a multiplication (much faster than regular pow)
    // and the square root is likely also much faster than any other root due to
    // dedicated hardware for it on the GPU.
    return pow(half3(base_color), 2) * fraction;
}

kernel void fill_color_buffer(device half3 *atom_color [[ buffer(0) ]],
                              const device uint8_t *atom_element [[ buffer(1) ]],
                              const device int16_t *subunitIndex [[ buffer(2) ]],
                              const device uint8_t *atom_residue [[ buffer(3) ]],
                              const device uint8_t *atom_secondary_structure [[ buffer(4) ]],
                              device FillColorInput &color_input [[ buffer(5) ]],
                              constant uint32_t & totalAtomCount [[ buffer(6) ]],
                              uint i [[ thread_position_in_grid ]],
                              uint l [[ thread_position_in_threadgroup ]]) {
    // TODO: Remove once all devices have non-uniform threadgroup size support
    if (i >= totalAtomCount) {
        return;
    }
    
    half3 final_color = half3(0.0, 0.0, 0.0);
    
    // NOTE: To blend the colors we 'should' use the standard Gamma of 2.2. Instead
    // we square the numbers and take the square root, which is the same as using a
    // Gamma of 2.0. However, since the final color is the same, and it looks close
    // enough, we use the square/square root 'trick', since the pow([...], 2) is
    // likely compiler-optimized to a multiplication (much faster than regular pow)
    // and the square root is likely also much faster than any other root due to
    // dedicated hardware for it on the GPU.
    if (color_input.colorByElement != 0.0) {
        final_color += pow(half3( color_input.element_color[atom_element[i]].rgb ), 2) * color_input.colorByElement;
    }
    if (color_input.colorByChain != 0.0) {
        final_color += pow(half3( color_input.subunit_color[subunitIndex[i]].rgb), 2) * color_input.colorByChain;
    }
    if (color_input.colorByResidue != 0.0) {
        final_color += pow(half3( color_input.residue_color[atom_residue[i]].rgb), 2) * color_input.colorByResidue;
    }
    if (color_input.colorBySecondaryStructure != 0.0) {
        final_color += pow(half3( color_input.secondary_structure_color[atom_secondary_structure[i]].rgb), 2)
            * color_input.colorBySecondaryStructure;
    }
    
    atom_color[i] = sqrt(final_color);
}
