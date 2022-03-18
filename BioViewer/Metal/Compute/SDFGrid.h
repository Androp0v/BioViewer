//
//  SDFGrid.h
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 18/3/22.
//

#ifndef SDFGrid_h
#define SDFGrid_h

typedef struct {
    
    /// Number of points per grid side.
    int32_t grid_resolution;
    /// Grid side size (in Armstrongs).
    float grid_size;
    /// Number of atoms contained inside the grid.
    int32_t number_of_atoms;
    
} SDFGrid;

#endif /* SDFGrid_h */
