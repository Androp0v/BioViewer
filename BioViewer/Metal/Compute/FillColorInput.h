//
//  FillColorInput.h
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/1/22.
//

#ifndef FillColorInput_h
#define FillColorInput_h

/// Maximum number of colours that can be passed down to the GPU using FrameData.
#define MAX_ATOM_COLORS 64

typedef struct {
    
    /// Color by subunit, used as a boolean.
    int8_t colorBySubunit;
    
    /// Displayed atomic color in hard-spheres visualization mode.
    /// When spheres are coloured by element, only the first 6 elements of the array will be used.
    /// When spheres are coloured by subunit, all the array may be used.
    simd_float4 atom_color [MAX_ATOM_COLORS];
    
} FillColorInput;

#endif /* FillColorInput_h */
