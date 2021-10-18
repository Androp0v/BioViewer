//
//  GeneratedVertex.h
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 18/10/21.
//

#ifndef GeneratedVertex_h
#define GeneratedVertex_h

#include <simd/simd.h>
#include <simd/vector_types.h>

typedef struct {

    /// Position of the vertex in world space
    simd_float3 position;

    /// Normal of the surface tangent to the vertex in world space
    simd_float3 normal; // TO-DO: Use simd_half3 when supported...

} GeneratedVertex;

#endif /* GeneratedVertex_h */
