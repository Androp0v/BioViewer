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
#define MAX_RESIDUE_COLORS 35
#define MAX_SECONDARY_STRUCTURE_COLORS 4

typedef struct {
    
    /// Color by element, used as a percentage (is always 0 or 1 outside animations).
    float colorByElement;
    /// Color by residue type, used as a percentage (is always 0 or 1 outside animations).
    float colorByResidue;
    /// Color by subunit, used as a percentage (is always 0 or 1 outside animations).
    float colorBySubunit;
    /// Color by secondary structure, used as a percentage (is always 0 or 1 outside animations).
    float colorBySecondaryStructure;
    
    /// Color used when coloring by element.
    simd_float4 element_color [MAX_ELEMENT_COLORS];
    /// Color used when coloring by subunit.
    simd_float4 subunit_color [MAX_SUBUNIT_COLORS];
    /// Color used when coloring by amino acid.
    simd_float4 residue_color [MAX_RESIDUE_COLORS];
    /// Color used when coloring by secondary structure.
    simd_float4 secondary_structure_color [MAX_SECONDARY_STRUCTURE_COLORS];
    
} FillColorInput;

#endif /* FillColorInput_h */
