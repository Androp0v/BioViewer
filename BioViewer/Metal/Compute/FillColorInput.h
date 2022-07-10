//
//  FillColorInput.h
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/1/22.
//

#ifndef FillColorInput_h
#define FillColorInput_h

/// Maximum number of colours that can be passed down to the GPU.
#define MAX_SUBUNIT_COLORS 512
#define MAX_ELEMENT_COLORS 128

typedef struct {
    
    /// Color by element, used as a percentage (is always 0 or 1 outside animations).
    float colorByElement;
    /// Color by subunit, used as a percentage (is always 0 or 1 outside animations).
    float colorBySubunit;
    
    /// Color used when coloring by element.
    simd_float4 element_color [MAX_ELEMENT_COLORS];
    /// Color used when coloring by subunit.
    simd_float4 subunit_color [MAX_SUBUNIT_COLORS];
    
} FillColorInput;

#endif /* FillColorInput_h */
