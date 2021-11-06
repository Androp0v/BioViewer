# BioViewer
Protein (.pdb, .cif and .fasta) viewer for iPhone, iPad and Mac, using SwiftUI + SceneKit.

![ProteinView](ProteinView.png)

## Implemented Metal optimizations
- Dynamic data is updated using a triple buffering scheme (the dynamic uniform buffer *FrameData* of the next render passes is computed and populated on the CPU while a previous GPU render command encoder is still running).
- Spheres are drawn using impostor geometries (a single *quad* is used for each sphere, and the sphere itself is drawn on the shading stage, allowing for far lower memory utilization and triangle count). This is a separate rendering pass from the one drawing the opaque geometries (currently unused).
- It does **NOT** use a rolling GPU time average to stabilize the framerate as in the initial testing it delievered consistently lower framerates (which is expected, but the perceived effect was not an improvement).
- It does **NOT** use frustrum culling (yet!).
- It does **NOT** use anti-aliasing (yet!).

## Feature wish list
- Open PDB, CIF and FASTA files.
- Full drag & drop support on iOS, iPadOS and macOS.
- Support to open files from mail attachments, other apps and the Files app.
- Visual representation from PDB, CIF and FASTA files.
- Alignment of small FASTA files.
- Small scale protein folding from FASTA files + visual representation.
- Flexible coloring options for residues/atom types.
