//
//  SharedDataStructs.h
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 8/1/22.
//

#ifndef SharedDataStructs_h
#define SharedDataStructs_h

/// Supported number of (different) atom types.
#define ATOM_TYPE_COUNT 64

typedef struct {
    /// Radius of each atom type (C, H, N, O, S, Others).
    float atomRadius [ATOM_TYPE_COUNT];
} AtomRadii;

#endif /* SharedDataStructs_h */
