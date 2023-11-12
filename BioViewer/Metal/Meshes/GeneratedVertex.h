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

typedef struct {

    /// Position of the vertex in world space
    simd_float3 position;
    
    /// Position of the atom center in world space
    simd_float3 billboard_world_center;
    
    /// Position of the atomic center in world space
    simd_float2 billboardMapping;
    
    /// Atom radii
    float atom_radius;

} BillboardVertex;

typedef struct {

    /// Position of the first atom in world space.
    simd_float3 atom_A;
    
    /// Position of the first atom in world space.
    simd_float3 atom_B;
    
    /// Cylinder center in world space.
    simd_float3 cylinder_center;
    
    /// Bond radius.
    float bond_radius;

} RawBondStruct;

typedef struct {
    
    /// Position of the vertex in world space
    simd_float3 position;
    
} DebugPoint;

#endif /* GeneratedVertex_h */
