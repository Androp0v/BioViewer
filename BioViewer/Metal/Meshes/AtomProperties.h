//
//  AtomProperties.h
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 1/6/21.
//

#ifndef AtomProperties_h
#define AtomProperties_h

#include <simd/simd.h>

// Carbon, Nitrogen, Hydrogen, Oxygen, Sulfur, Others
constant float atomRadius [] = {1.70, 1.55, 1.52, 1.80, 1.10, 1.0};

// Carbon, Nitrogen, Hydrogen, Oxygen, Sulfur, Others
constant float4 atomColor [] = {float4(0.423, 0.733, 0.235, 1.0),
                                float4(0.091, 0.148, 0.556, 1.0),
                                float4(0.517, 0.517, 0.517, 1.0),
                                float4(1.000, 0.149, 0.000, 1.0),
                                float4(1.000, 0.780, 0.349, 1.0),
                                float4(0.517, 0.517, 0.517, 1.0)};

#endif /* AtomProperties_h */
